import 'dart:convert';
import 'dart:math' as math;

import 'package:wonky_slides_core/clipboard.dart' show SlidesClipboardCodec;
import 'package:wonky_slides_core/icons.dart' show LucideGlyphs;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart' show SuRect;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_sync_models/ids.dart' show Base62Uuid;

import '../../platform/mcp/drive_tool_handlers.dart';
import '../../platform/mcp/tool_support.dart';
import '../headless/headless_deck.dart';
import 'slides_content.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';
import 'slides_writes.dart';

/// Element and text tools (Slides 11 §3.8).
abstract final class SlidesElementHandlers {
  static String _plural(int n, String one) => '$n $one${n == 1 ? '' : 's'}';

  static const _textKinds = {ElementKind.text, ElementKind.shape};

  /// The resolved frame of element [id] (slide space; group children in
  /// their group's space).
  static SuRect? frameOf(DeckModel m, String id) {
    final e = m.element(id);
    final owner = e?.slideId;
    if (owner == null) return e?.frame;
    final rs = SlideResolver(m).resolve(owner);
    SuRect? find(List<ResolvedElement> list) {
      for (final x in list) {
        if (x.id == id) return x.frame;
        final c = find(x.children);
        if (c != null) return c;
      }
      return null;
    }

    return find(rs?.elements ?? const []) ?? e?.frame;
  }

  // -------------------------------------------------------- add_elements

  static Future<ToolResult> addElements(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final list = a.list('elements')!;
    // Images are copied into the deck before the write.
    final images = <int, PreparedImage>{};
    for (final (i, raw) in list.indexed) {
      final e = (raw! as Map).cast<String, Object?>();
      if (e['kind'] == 'image') {
        final im = (e['image'] as Map?)?.cast<String, Object?>();
        if (im == null) {
          throw SlidesMcp.invalid(
            'An image needs image.file_uuid.',
            pointer: '/elements/$i/image',
          );
        }
        images[i] = await SlidesContent.prepareImage(
          ctx,
          t,
          '${im['file_uuid']}',
          pointer: '/elements/$i/image/file_uuid',
        );
      }
    }
    final warnings = <SlidesWarning>[];
    final created = <String>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.add_elements',
      label: 'add_elements (${list.length})',
      warnings: warnings,
      build: (s) {
        final m = s.model;
        final slideId = SlidesMcp.slideId(m, a.values['slide']);
        for (final (i, raw) in list.indexed) {
          final e = (raw! as Map).cast<String, Object?>();
          final id = _addElement(
            s,
            slideId,
            e,
            pointer: '/elements/$i',
            image: images[i],
            warnings: warnings,
          );
          created.add(id);
        }
      },
    );
    final extra = <String, Object?>{'element_ids': created};
    if (images.values.any((i) => i.copied)) {
      extra['storage'] = await DriveToolHandlers.storageJson(ctx);
    }
    return SlidesWrites.result(
      o,
      'Added ${_plural(created.length, 'element')}',
      extra,
    );
  }

  static String _addElement(
    DeckSteps s,
    String slideId,
    Map<String, Object?> e, {
    required String pointer,
    PreparedImage? image,
    required List<SlidesWarning> warnings,
  }) {
    final m = s.model;
    final kind = '${e['kind']}';
    final (sw, sh) = SlidesInput.slideSize(m);
    final style = (e['style'] as Map?)?.cast<String, Object?>() ?? const {};
    final frameArg = (e['frame'] as Map?)?.cast<String, Object?>();
    final placement = (e['placement'] as Map?)?.cast<String, Object?>();
    SuRect fallback(double w, double h) =>
        SuRect((sw - w) / 2, (sh - h) / 2, w, h);
    SuRect frame(SuRect fb) => SlidesInput.frame(
      m,
      frame: frameArg,
      placement: placement,
      fallback: fb,
      pointer: pointer,
    );
    final columns = <String, Object?>{
      if (e['name'] is String) SlidesCols.name: e['name'],
      if (e['alt_text'] is String) ElementCols.altText: e['alt_text'],
      if (e['decorative'] == true) ElementCols.decorative: true,
      if (e['match_key'] is String) ElementCols.matchKey: e['match_key'],
      if (e['link'] case final Map<Object?, Object?> l)
        ElementCols.linkJson: _link(m, l, '$pointer/link'),
    };
    columns.addAll(SlidesInput.styleColumns(style, pointer: '$pointer/style'));
    final textPatch = SlidesInput.textStylePatch(
      (style['text'] as Map?)?.cast<String, Object?>(),
    );
    String? text() => e['text'] == null
        ? null
        : SlidesInput.text(
            m,
            e['text'],
            pointer: '$pointer/text',
            warnings: warnings,
          );
    ElementSpec spec;
    switch (kind) {
      case 'text':
        final f = frame(fallback(sw * 0.6, sh * 0.2));
        spec = ElementSpec(
          kind: ElementKind.text,
          x: f.x,
          y: f.y,
          width: f.width,
          height: f.height,
          rotation: (frameArg?['rotation'] as num?)?.toDouble(),
          columns: {
            ...columns,
            SlidesCols.text: ?text(),
            ElementCols.textStyleJson: jsonEncode({
              'v': 1,
              'autofit': 'resize',
              ...?textPatch,
            }),
          },
        );
      case 'shape':
        final f = frame(fallback(sw * 0.25, sh * 0.25));
        final shape = (e['shape'] as Map?)?.cast<String, Object?>() ?? {};
        final data = <String, Object?>{
          'v': 1,
          'geometry': shape['geometry'] ?? 'rect',
          if (shape['adjust'] is Map) 'adjust': shape['adjust'],
          if (columns[ElementCols.dataJson] case final String d)
            ...((jsonDecode(d) as Map).cast<String, Object?>()..remove('v')),
        };
        spec = ElementSpec(
          kind: ElementKind.shape,
          x: f.x,
          y: f.y,
          width: f.width,
          height: f.height,
          rotation: (frameArg?['rotation'] as num?)?.toDouble(),
          columns: {
            ...columns,
            ElementCols.dataJson: jsonEncode(data),
            SlidesCols.text: ?text(),
            if (textPatch != null)
              ElementCols.textStyleJson: jsonEncode({'v': 1, ...textPatch}),
          },
        );
      case 'line':
        spec = _line(
          m,
          (e['line'] as Map?)?.cast<String, Object?>() ?? const {},
          columns,
          pointer: '$pointer/line',
        );
      case 'image':
        final im = (e['image'] as Map).cast<String, Object?>();
        final natural = SuRect(
          0,
          0,
          image!.width.toDouble(),
          image.height.toDouble(),
        );
        final scale = math.min(
          1.0,
          math.min(sw * 0.8 / natural.width, sh * 0.8 / natural.height),
        );
        final box = frame(
          fallback(natural.width * scale, natural.height * scale),
        );
        Map<String, Object?>? crop = (im['crop'] as Map?)
            ?.cast<String, Object?>();
        var f = box;
        if (im['fit'] == 'fill' && crop == null) {
          crop = _coverCrop(image, box);
        } else if (frameArg != null || placement != null) {
          f = SlidesContent.fit(image, box);
        }
        spec = ElementSpec(
          kind: ElementKind.image,
          x: f.x,
          y: f.y,
          width: f.width,
          height: f.height,
          columns: {
            ...columns,
            ElementCols.dataJson: jsonEncode(
              image.data(crop: crop, mask: im['mask'] as String?),
            ),
          },
        );
      case 'table':
        final tb = (e['table'] as Map).cast<String, Object?>();
        final rows = [
          for (final r in tb['rows']! as List) [...(r as List)],
        ];
        final f = frame(
          SuRect(
            sw * 0.1,
            sh * 0.25,
            sw * 0.8,
            math.min(sh * 0.6, 90.0 * rows.length),
          ),
        );
        final id = SlidesContent.insertTable(
          s,
          slideId,
          f,
          rows,
          headerRow: tb['header_row'] as bool? ?? true,
          columnWidths: (tb['column_widths'] as List?)?.cast<num>(),
          pointer: '$pointer/table',
          warnings: warnings,
        );
        final props = columns
          ..remove(ElementCols.dataJson)
          ..remove(SlidesCols.text);
        if (props.isNotEmpty) _setProps(s, [id], props);
        _z(s, id, e['z']);
        return id;
      case 'icon':
        final icon = (e['icon'] as Map?)?.cast<String, Object?>() ?? const {};
        final f = frame(fallback(sh * 0.2, sh * 0.2));
        Map<String, Object?> data;
        if (icon['emoji'] is String) {
          data = {'v': 1, 'set': 'emoji', 'char': icon['emoji']};
        } else {
          final name = '${icon['name'] ?? ''}';
          if (LucideGlyphs.codePoint(name) == null) {
            throw SlidesMcp.invalid(
              'Unknown Lucide icon "$name" (names are kebab-case, e.g. '
              '"rocket", "chart-line").',
              pointer: '$pointer/icon/name',
            );
          }
          data = {
            'v': 1,
            'set': 'lucide',
            'name': name,
            'strokeWidth': LucideGlyphs.defaultStrokeWidth,
          };
        }
        spec = ElementSpec(
          kind: ElementKind.icon,
          x: f.x,
          y: f.y,
          width: f.width,
          height: f.height,
          columns: {...columns, ElementCols.dataJson: jsonEncode(data)},
        );
      default:
        throw SlidesMcp.invalid(
          'Unknown kind "$kind".',
          pointer: '$pointer/kind',
        );
    }
    final plan = s.run(InsertElements(slideId, [spec]));
    final id = (plan.result['elementIds']! as List).single as String;
    _z(s, id, e['z']);
    return id;
  }

  static void _z(DeckSteps s, String id, Object? z) {
    if (z == 'back') s.run(ReorderZ([id], ZOrderOp.toBack));
  }

  static Map<String, Object?> _coverCrop(PreparedImage image, SuRect box) {
    final fa = box.width / box.height;
    final ia = image.width / image.height;
    if (ia > fa) {
      final c = (1 - fa / ia) / 2;
      return {'l': c, 't': 0, 'r': c, 'b': 0};
    }
    final c = (1 - ia / fa) / 2;
    return {'l': 0, 't': c, 'r': 0, 'b': c};
  }

  static String _link(DeckModel m, Map<dynamic, dynamic> l, String pointer) {
    if (l['slide'] != null) {
      return jsonEncode({
        'v': 1,
        'slideId': SlidesMcp.slideId(m, l['slide'], pointer: '$pointer/slide'),
      });
    }
    final url = SlidesText.link('${l['url'] ?? ''}');
    if (url == null) {
      throw SlidesMcp.invalid(
        'Links must be https:// or mailto: URLs.',
        pointer: '$pointer/url',
      );
    }
    return jsonEncode({'v': 1, 'url': url});
  }

  /// A line between two points or element sites (03 §6.4).
  static ElementSpec _line(
    DeckModel m,
    Map<String, Object?> line,
    Map<String, Object?> columns, {
    required String pointer,
  }) {
    (double, double, String?, String?) end(Object? v, String key) {
      if (v is! Map) {
        throw SlidesMcp.invalid(
          'line.$key needs {x, y} or {element, site}.',
          pointer: '$pointer/$key',
        );
      }
      if (v['element'] != null) {
        final id = SlidesMcp.elementId(
          m,
          v['element'],
          pointer: '$pointer/$key/element',
        );
        final f = frameOf(m, id)!;
        final site = '${v['site'] ?? 'center'}';
        final (x, y) = switch (site) {
          'top' => (f.x + f.width / 2, f.y),
          'right' => (f.x + f.width, f.y + f.height / 2),
          'bottom' => (f.x + f.width / 2, f.y + f.height),
          'left' => (f.x, f.y + f.height / 2),
          _ => (f.x + f.width / 2, f.y + f.height / 2),
        };
        return (x, y, id, site);
      }
      final x = v['x'], y = v['y'];
      if (x is! num || y is! num) {
        throw SlidesMcp.invalid(
          'line.$key needs numbers x and y.',
          pointer: '$pointer/$key',
        );
      }
      return (x.toDouble(), y.toDouble(), null, null);
    }

    final a = end(line['from'], 'from');
    final b = end(line['to'], 'to');
    final x = math.min(a.$1, b.$1), y = math.min(a.$2, b.$2);
    final w = (a.$1 - b.$1).abs(), h = (a.$2 - b.$2).abs();
    double rel(double v, double o, double size) =>
        size == 0 ? 0 : ((v - o) / size * 1e6).roundToDouble() / 1e6;
    Map<String, Object?> endpoint((double, double, String?, String?) p) => {
      'x': rel(p.$1, x, w),
      'y': rel(p.$2, y, h),
      'connect': p.$3 == null
          ? null
          : {'elementId': Base62Uuid.encode(p.$3!), 'site': p.$4},
    };
    final arrows = (line['arrows'] as Map?)?.cast<String, Object?>();
    Map<String, Object?>? stroke = columns[ElementCols.strokeJson] is String
        ? (jsonDecode(columns[ElementCols.strokeJson]! as String) as Map)
              .cast<String, Object?>()
        : null;
    if (arrows != null) {
      stroke = {
        'v': 1,
        ...?stroke,
        if (arrows['start'] is String) 'startArrow': arrows['start'],
        if (arrows['end'] is String) 'endArrow': arrows['end'],
      };
    }
    return ElementSpec(
      kind: ElementKind.line,
      x: x,
      y: y,
      width: w,
      height: h,
      columns: {
        ...columns,
        ElementCols.dataJson: jsonEncode({
          'v': 1,
          'routing': line['routing'] ?? 'straight',
          'start': endpoint(a),
          'end': endpoint(b),
          'waypoints': const <Object?>[],
        }),
        if (stroke != null) ElementCols.strokeJson: jsonEncode(stroke),
      },
    );
  }

  static void _setProps(DeckSteps s, List<String> ids, Map<String, Object?> c) {
    Patch<String?>? p(String k) =>
        c.containsKey(k) ? Patch(c[k] as String?) : null;
    s.run(
      SetElementProps(
        ids,
        fillJson: p(ElementCols.fillJson),
        strokeJson: p(ElementCols.strokeJson),
        effectsJson: p(ElementCols.effectsJson),
        opacity: c.containsKey(ElementCols.opacity)
            ? Patch(c[ElementCols.opacity] as double?)
            : null,
        elementName: p(SlidesCols.name),
        altText: p(ElementCols.altText),
        decorative: c[ElementCols.decorative] as bool?,
        linkJson: p(ElementCols.linkJson),
        matchKey: c[ElementCols.matchKey] as String?,
      ),
    );
  }

  // ----------------------------------------------------- update_elements

  static Future<ToolResult> updateElements(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final list = a.list('updates')!;
    final warnings = <SlidesWarning>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.update_elements',
      label: 'update_elements (${list.length})',
      force: a.boolean('force') ?? false,
      warnings: warnings,
      build: (s) {
        final m = s.model;
        for (final (i, raw) in list.indexed) {
          final u = (raw! as Map).cast<String, Object?>();
          final p = '/updates/$i';
          final id = SlidesMcp.elementId(
            m,
            u['element'],
            pointer: '$p/element',
          );
          final rec = m.element(id)!;
          final f = (u['frame'] as Map?)?.cast<String, Object?>();
          final flip = (u['flip'] as Map?)?.cast<String, Object?>();
          double? n(Object? v) => (v as num?)?.toDouble();
          if (f != null || u['rotation'] != null || flip != null) {
            s.run(
              UpdateFrames([
                FrameUpdate(
                  id,
                  x: n(f?['x']),
                  y: n(f?['y']),
                  width: n(f?['w']),
                  height: n(f?['h']),
                  rotation: n(u['rotation'] ?? f?['rotation']),
                  flipH: flip?['h'] as bool?,
                  flipV: flip?['v'] as bool?,
                ),
              ]),
            );
          }
          final style = (u['style'] as Map?)?.cast<String, Object?>();
          final props = <String, Object?>{
            if (style != null)
              ...SlidesInput.styleColumns(
                style,
                current: rec,
                pointer: '$p/style',
              ),
            if (u.containsKey('name')) SlidesCols.name: u['name'],
            if (u.containsKey('alt_text')) ElementCols.altText: u['alt_text'],
            if (u['decorative'] is bool)
              ElementCols.decorative: u['decorative'],
            if (u['match_key'] is String) ElementCols.matchKey: u['match_key'],
            if (u.containsKey('link'))
              ElementCols.linkJson: u['link'] == null
                  ? null
                  : _link(m, u['link']! as Map, '$p/link'),
          };
          final data = props.remove(ElementCols.dataJson);
          if (data is String) s.run(SetElementData(id, data));
          if (props.isNotEmpty) _setProps(s, [id], props);
          if (u['locked'] is bool || u['hidden'] is bool) {
            s.run(
              SetElementProps(
                [id],
                locked: u['locked'] as bool?,
                hidden: u['hidden'] as bool?,
              ),
            );
          }
          final textPatch = SlidesInput.textStylePatch(
            (style?['text'] as Map?)?.cast<String, Object?>(),
          );
          if (textPatch != null && textPatch.isNotEmpty) {
            s.run(SetTextBoxStyle([id], textPatch));
          }
          if (u.containsKey('text')) {
            requireText(rec);
            s.run(
              SetText(
                ElementText(id),
                SlidesInput.text(
                  m,
                  u['text'],
                  pointer: '$p/text',
                  warnings: warnings,
                  elementId: id,
                ),
              ),
            );
          }
          final z = switch (u['z']) {
            'front' => ZOrderOp.toFront,
            'back' => ZOrderOp.toBack,
            'forward' => ZOrderOp.forward,
            'backward' => ZOrderOp.backward,
            _ => null,
          };
          if (z != null) s.run(ReorderZ([id], z));
        }
      },
    );
    return SlidesWrites.result(o, 'Updated ${_plural(list.length, 'element')}');
  }

  /// Throws unless [e] holds text (text boxes and shapes).
  static void requireText(SlideElementRec e) {
    if (_textKinds.contains(e.kind)) return;
    throw McpToolException(
      SlidesErrorCode.invalidTarget,
      switch (e.kind) {
        ElementKind.table =>
          'Element ${e.id} is a table: use '
              'slides.set_table_cells.',
        ElementKind.code =>
          'Element ${e.id} is a code block: use '
              'slides.set_code_states.',
        _ => 'Element ${e.id} (${e.kind.name}) has no text.',
      },
      details: {'element_id': e.id, 'kind': e.kind.name},
    );
  }

  // ------------------------------------------------ delete, dup, group

  static Future<ToolResult> deleteElements(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    var n = 0;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.delete_elements',
      build: (s) {
        final ids = SlidesMcp.elementIds(s.model, a.list('elements'));
        n = ids.length;
        s.run(DeleteElements(ids));
      },
    );
    return SlidesWrites.result(o, 'Deleted ${_plural(n, 'element')}');
  }

  static Future<ToolResult> duplicateElements(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await SlidesMcp.edit(ctx, a);
    final created = <String>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.duplicate_elements',
      build: (s) {
        final m = s.model;
        final ids = SlidesMcp.elementIds(m, a.list('elements'));
        final owner = m.element(ids.first)!.slideId;
        if (owner == null || ids.any((id) => m.element(id)!.slideId != owner)) {
          throw SlidesMcp.invalid(
            'Elements to duplicate must be on one slide.',
            pointer: '/elements',
          );
        }
        final to = a.values['to_slide'] == null
            ? owner
            : SlidesMcp.slideId(m, a.values['to_slide'], pointer: '/to_slide');
        final offset = a.object('offset');
        final dx = (offset?['x'] as num?)?.toDouble() ?? 24;
        final dy = (offset?['y'] as num?)?.toDouble() ?? 24;
        final frames = [for (final id in ids) ?frameOf(m, id)];
        final x0 = frames.map((f) => f.x).reduce(math.min);
        final y0 = frames.map((f) => f.y).reduce(math.min);
        final plan = s.run(
          PasteElements(
            SlidesClipboardCodec.copyElements(m, ids),
            to,
            atX: x0 + dx,
            atY: y0 + dy,
          ),
        );
        created.addAll(
          (plan.result['elementIds'] as List? ?? const []).whereType<String>(),
        );
      },
    );
    return SlidesWrites.result(
      o,
      'Duplicated ${_plural(created.length, 'element')}',
      {'element_ids': created},
    );
  }

  static Future<ToolResult> groupElements(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    String? groupId;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.group_elements',
      build: (s) {
        final ids = SlidesMcp.elementIds(s.model, a.list('elements'));
        if (ids.length < 2) {
          throw SlidesMcp.invalid(
            'Group at least two elements.',
            pointer: '/elements',
          );
        }
        groupId = s.run(GroupElements(ids)).result['groupId'] as String?;
      },
    );
    return SlidesWrites.result(o, 'Grouped the elements', {
      'group_element_id': groupId,
    });
  }

  static Future<ToolResult> ungroupElements(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.ungroup_elements',
      build: (s) {
        final id = SlidesMcp.elementId(s.model, a.values['element']);
        SlidesMcp.elementOfKind(s.model, id, {ElementKind.group}, 'a group');
        s.run(UngroupElements([id]));
      },
    );
    return SlidesWrites.result(o, 'Ungrouped the elements');
  }

  static Future<ToolResult> alignElements(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final mode = switch (a.requireString('op')) {
      'left' => AlignMode.left,
      'center' => AlignMode.centerH,
      'right' => AlignMode.right,
      'top' => AlignMode.top,
      'middle' => AlignMode.middleV,
      'bottom' => AlignMode.bottom,
      'distribute_h' => AlignMode.distributeH,
      _ => AlignMode.distributeV,
    };
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.align_elements',
      build: (s) => s.run(
        AlignDistribute(
          SlidesMcp.elementIds(s.model, a.list('elements')),
          mode,
          reference: a.string('relative_to') == 'slide'
              ? AlignReference.slide
              : AlignReference.selection,
        ),
      ),
    );
    return SlidesWrites.result(o, 'Aligned the elements');
  }
}
