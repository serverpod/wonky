import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/widgets.dart' show Directionality, View;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/emoji.dart'
    show EmojiPickerKeys, showEmojiPickerDialog;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/icons.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/scene.dart' show ShapeLibrary;
import 'package:wonky_slides_core/schema.dart' show ElementCols;

import '../features/canvas/canvas_tools.dart';
import '../features/canvas/slide_canvas_controller.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/elements/common/element_dialogs.dart';
import '../features/elements/icon/icon_picker.dart';
import '../features/elements/line/line_tool.dart';
import '../features/elements/shape/shape_gallery.dart';
import '../features/elements/shape/shape_tool.dart';
import '../features/elements/style/element_style.dart';
import '../features/format_painter/format_painter.dart';
import '../features/spellcheck/text_inserts.dart';
import '../features/text_editing/text_editing_host.dart' show textEditingOf;
import '../l10n/slides_l10n.dart';
import 'slides_command.dart';

/// The object commands of SL-14 (Slides 03 §6.3, §6.4, §6.7, §7, §17.1;
/// 04 §4.4, §4.5, §4.7): insert shapes, lines/connectors, icons and emoji
/// (UI: arm the canvas tool or open the picker; agents and the canvas
/// tools: insert with a frame), change shape and quick styles, arrowheads
/// and routing, icon replace and stroke width, element groups, alt text
/// and names. Every mutating command is one undo step.
List<Command<CommandArgs>> objectCommands(ShellServices s) {
  CanvasTools.register(shapeToolFactory);
  CanvasTools.register(lineToolFactory);
  CanvasTools.register(paintFormatToolFactory);
  return [
    // ---- Insert (03 §6.3, §6.4, §6.7)
    SlidesCommand(
      'slides.insert.shape',
      label: (l) => l.cmdInsertShape,
      icon: LucideIcons.square,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      defaultBindings: const [KeyBinding('S')],
      keyScope: SlidesKeyScopes.canvas,
      argsSchema: JsonSchema.object(
        properties: {
          'geometry': JsonSchema.string(
            enumValues: ShapeLibrary.keys,
            description: 'Shape library key (omit: the last shape).',
          ),
          'x': const JsonSchema.number(),
          'y': const JsonSchema.number(),
          'width': const JsonSchema.number(),
          'height': const JsonSchema.number(),
          'pick': const JsonSchema.boolean(
            description: 'Choose the shape in the gallery dialog first.',
          ),
        },
      ),
      enabled: (ed, a) => ed.surfaceId != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) async {
        var geometry = a.string('geometry');
        if (a.boolean('pick') ?? false) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed('geometry is required');
          }
          geometry = await showShapeGalleryDialog(dc, selected: _lastShape);
          if (geometry == null) return const CommandResult.cancelled();
        }
        geometry ??= _lastShape;
        if (ShapeLibrary.of(geometry) == null) {
          return CommandResult.failed('Unknown shape $geometry');
        }
        _lastShape = geometry;
        final x = _num(a, 'x'), y = _num(a, 'y');
        final w = _num(a, 'width'), h = _num(a, 'height');
        if (x == null && !ctx.source.isAgent) {
          // UI: arm the tool (click or drag on the canvas, 03 §6.3).
          ed.armTool(ShapeInsert.toolName(geometry));
          _announce(ctx, ed, (l) => l.toolArmedShape);
          return ok({'armed': ed.armedTool});
        }
        final size = ShapeInsert.sizeOf(geometry);
        final box = _placed(ed, x, y, w ?? size.width, h ?? size.height);
        return _insert(
          ctx,
          ed,
          ElementSpec(
            kind: ElementKind.shape,
            x: box.$1,
            y: box.$2,
            width: box.$3,
            height: box.$4,
            columns: {
              ElementCols.dataJson: jsonEncode({'v': 1, 'geometry': geometry}),
            },
          ),
        );
      },
    ),
    SlidesCommand(
      'slides.insert.line',
      label: (l) => l.cmdInsertLine,
      icon: LucideIcons.slash,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      defaultBindings: const [KeyBinding('L')],
      keyScope: SlidesKeyScopes.canvas,
      argsSchema: const JsonSchema.object(
        properties: {
          'routing': JsonSchema.string(enumValues: lineRoutings),
          'arrows': JsonSchema.string(enumValues: lineArrowEnds),
          'start': _endpointSchema,
          'end': _endpointSchema,
        },
      ),
      enabled: (ed, a) => ed.surfaceId != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        final routing = a.string('routing') ?? _lastLine.$1;
        final arrows = a.string('arrows') ?? _lastLine.$2;
        _lastLine = (routing, arrows);
        var start = LineEnd.fromJson(a.values['start']);
        var end = LineEnd.fromJson(a.values['end']);
        if (start == null || end == null) {
          if (!ctx.source.isAgent) {
            ed.armTool(LineInsert.toolName(routing, arrows));
            _announce(ctx, ed, (l) => l.toolArmedLine);
            return ok({'armed': ed.armedTool});
          }
          final (w, h) = _slideSize(ed);
          start = LineEnd(w / 2 - LineInsert.clickLength / 2, h / 2);
          end = LineEnd(w / 2 + LineInsert.clickLength / 2, h / 2);
        }
        return _insert(
          ctx,
          ed,
          LineInsert.spec(start, end, routing: routing, arrows: arrows),
        );
      },
    ),
    SlidesCommand(
      'slides.insert.icon',
      label: (l) => l.cmdInsertIcon,
      icon: LucideIcons.shapes,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'name': JsonSchema.string(
            description: 'Lucide icon name (omit to choose in the picker).',
          ),
          'strokeWidth': JsonSchema.number(minimum: 1, maximum: 3),
          'color': JsonSchema.string(description: 'ColorRef (theme:accent1).'),
          'x': JsonSchema.number(),
          'y': JsonSchema.number(),
          'size': JsonSchema.number(),
        },
      ),
      enabled: (ed, a) => ed.surfaceId != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) async {
        var name = a.string('name');
        var stroke = _num(a, 'strokeWidth') ?? LucideGlyphs.defaultStrokeWidth;
        var color = a.string('color');
        if (name == null) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed('name is required');
          }
          final r = await showIconPicker(
            dc,
            services: ed.services,
            theme: ElementStyle.themeOf(ed),
            strokeWidth: stroke,
            color: color,
          );
          if (r == null) return const CommandResult.cancelled();
          (name, stroke, color) = (r.name, r.strokeWidth, r.color);
        }
        final icon = LucideCatalog.of(name);
        if (icon == null) return CommandResult.failed('Unknown icon $name');
        if (color != null && !ElementStyle.validColor(color)) {
          return CommandResult.failed('Invalid color $color');
        }
        final size = _num(a, 'size') ?? 160;
        final box = _placed(ed, _num(a, 'x'), _num(a, 'y'), size, size);
        return _insert(
          ctx,
          ed,
          ElementSpec(
            kind: ElementKind.icon,
            x: box.$1,
            y: box.$2,
            width: box.$3,
            height: box.$4,
            columns: {
              ElementCols.dataJson: jsonEncode({
                'v': 1,
                'set': 'lucide',
                'name': icon.name,
                'strokeWidth': LucideGlyphs.snapStrokeWidth(stroke),
              }),
              if (color != null)
                ElementCols.strokeJson: jsonEncode({'v': 1, 'color': color}),
            },
          ),
        );
      },
    ),
    SlidesCommand(
      'slides.insert.emoji',
      label: (l) => l.cmdInsertEmoji,
      icon: LucideIcons.smile,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'char': JsonSchema.string(
            description: 'The emoji (omit to choose in the picker).',
          ),
          'x': JsonSchema.number(),
          'y': JsonSchema.number(),
          'size': JsonSchema.number(),
        },
      ),
      enabled: (ed, a) => ed.surfaceId != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) async {
        var char = a.string('char');
        if (char == null || char.isEmpty) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed('char is required');
          }
          final done = Completer<String?>();
          await showEmojiPickerDialog(
            dc,
            prefs: slidesEmojiPrefs(ed.services),
            keys: EmojiPickerKeys.slides,
            onSelected: (e) {
              if (!done.isCompleted) done.complete(e);
            },
          );
          if (!done.isCompleted) done.complete(null);
          char = await done.future;
          if (char == null) {
            if (isEditingText(ed)) {
              textEditingOf(ed).editorFocus.requestFocus();
            }
            return const CommandResult.cancelled();
          }
        }
        if (char.runes.length > 16) {
          return CommandResult.failed(slidesL10nOf(ed.services).errorOneEmoji);
        }
        // While text is edited the emoji is typed into it (it stays text,
        // 03 §6.7; SL-44); otherwise it becomes an emoji object.
        if (insertIntoEditedText(ed, char)) return ok();
        final size = _num(a, 'size') ?? 240;
        final box = _placed(ed, _num(a, 'x'), _num(a, 'y'), size, size);
        return _insert(
          ctx,
          ed,
          ElementSpec(
            kind: ElementKind.icon,
            x: box.$1,
            y: box.$2,
            width: box.$3,
            height: box.$4,
            columns: {
              ElementCols.dataJson: jsonEncode({
                'v': 1,
                'set': 'emoji',
                'char': char,
              }),
            },
          ),
        );
      },
    ),

    // ---- Shapes (03 §6.3)
    SlidesCommand(
      'slides.shape.change',
      label: (l) => l.cmdShapeChange,
      icon: LucideIcons.shapes,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: JsonSchema.object(
        properties: {
          'geometry': JsonSchema.string(enumValues: ShapeLibrary.keys),
          'ids': const JsonSchema.array(JsonSchema.string()),
        },
      ),
      enabled: (ed, a) => _ofKind(ed, a, ElementKind.shape).isNotEmpty,
      reason: (l, ed) => l.reasonSelectShape,
      run: (ctx, ed, a) async {
        final shapes = _ofKind(ed, a, ElementKind.shape);
        var geometry = a.string('geometry');
        if (geometry == null) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed('geometry is required');
          }
          final current = shapes.first.data?['geometry'];
          geometry = await showShapeGalleryDialog(
            dc,
            selected: current is String ? current : null,
          );
          if (geometry == null) return const CommandResult.cancelled();
        }
        if (ShapeLibrary.of(geometry) == null) {
          return CommandResult.failed('Unknown shape $geometry');
        }
        for (final e in shapes) {
          // Keeps frame, text, style, builds and matchKey; the geometry's
          // own adjusts and custom path go.
          final data = {...?e.data}
            ..remove('adjust')
            ..remove('path')
            ..remove('fillRule');
          ed.apply(
            ctx,
            SetElementData(
              e.id,
              jsonEncode({...data, 'v': 1, 'geometry': geometry}),
            ),
          );
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.shape.applyQuickStyle',
      label: (l) => l.cmdShapeApplyQuickStyle,
      icon: LucideIcons.palette,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'index': JsonSchema.integer(minimum: 0, maximum: 7),
          'ids': JsonSchema.array(JsonSchema.string()),
        },
        required: ['index'],
      ),
      enabled: (ed, a) => _ofKind(ed, a, ElementKind.shape).isNotEmpty,
      reason: (l, ed) => l.reasonSelectShape,
      run: (ctx, ed, a) {
        final theme = ElementStyle.themeOf(ed);
        final styles = ElementStyle.quickStyles(theme);
        final i = a.integer('index') ?? 0;
        if (i < 0 || i >= styles.length) {
          return const CommandResult.failed('No such quick style');
        }
        final q = styles[i];
        final shapes = _ofKind(ed, a, ElementKind.shape);
        final ids = [for (final e in shapes) e.id];
        ed.apply(
          ctx,
          SetElementProps(
            ids,
            fillJson: Patch(
              q.fill == null ? null : jsonEncode(q.fill!.toJson()),
            ),
            strokeJson: Patch(
              q.stroke == null ? null : jsonEncode(q.stroke!.toJson()),
            ),
          ),
        );
        final text = q.textColor?.json;
        ed.apply(
          ctx,
          SetTextBoxStyle(ids, {
            'defaults': {'color': text},
          }),
        );
        return ok();
      },
    ),

    // ---- Lines (03 §6.4)
    SlidesCommand(
      'slides.line.setArrow',
      label: (l) => l.cmdLineSetArrow,
      icon: LucideIcons.arrowRight,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'end': JsonSchema.string(enumValues: ['start', 'end', 'both']),
          'style': JsonSchema.string(enumValues: arrowStyles),
          'size': JsonSchema.string(enumValues: arrowSizes),
          'ids': JsonSchema.array(JsonSchema.string()),
        },
      ),
      enabled: (ed, a) => _ofKind(ed, a, ElementKind.line).isNotEmpty,
      reason: (l, ed) => l.reasonSelectLine,
      run: (ctx, ed, a) {
        final end = a.string('end') ?? 'end';
        final style = a.string('style');
        final size = a.string('size');
        if (style == null && size == null) {
          return const CommandResult.failed('style or size is required');
        }
        final patch = <String, Object?>{
          if (style != null && end != 'end')
            'startArrow': style == 'none' ? null : style,
          if (style != null && end != 'start')
            'endArrow': style == 'none' ? null : style,
          'arrowSize': ?size,
        };
        for (final e in _ofKind(ed, a, ElementKind.line)) {
          final next = ElementStyle.merge(e.record.strokeMap, patch)
            ..remove('v');
          ed.apply(
            ctx,
            SetElementProps(
              [e.id],
              strokeJson: Patch(
                next.isEmpty ? null : ElementStyle.encode(next),
              ),
            ),
          );
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.line.setRouting',
      label: (l) => l.cmdLineSetRouting,
      icon: LucideIcons.spline,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'routing': JsonSchema.string(enumValues: lineRoutings),
          'ids': JsonSchema.array(JsonSchema.string()),
        },
        required: ['routing'],
      ),
      enabled: (ed, a) => _ofKind(ed, a, ElementKind.line).isNotEmpty,
      reason: (l, ed) => l.reasonSelectLine,
      checked: (ed, a) {
        final lines = _ofKind(ed, a, ElementKind.line);
        if (lines.isEmpty || a.string('routing') == null) return null;
        return lines.every(
          (e) => (e.data?['routing'] ?? 'straight') == a.string('routing'),
        );
      },
      run: (ctx, ed, a) {
        final routing = a.requireString('routing');
        for (final e in _ofKind(ed, a, ElementKind.line)) {
          ed.apply(
            ctx,
            SetElementData(
              e.id,
              jsonEncode({
                ...?e.data,
                'v': 1,
                'routing': routing,
                'waypoints': const <Object?>[],
              }),
            ),
          );
        }
        return ok();
      },
    ),

    // ---- Icons (03 §6.7)
    SlidesCommand(
      'slides.icon.replace',
      label: (l) => l.cmdIconReplace,
      icon: LucideIcons.replace,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'name': JsonSchema.string(description: 'Lucide icon name.'),
          'id': JsonSchema.string(),
        },
      ),
      enabled: (ed, a) => _icon(ed, a) != null,
      reason: (l, ed) => l.reasonSelectIcon,
      run: (ctx, ed, a) async {
        final e = _icon(ed, a)!;
        var name = a.string('name');
        final data = e.data ?? const <String, Object?>{};
        final stroke = (data['strokeWidth'] as num?)?.toDouble() ?? 2;
        if (name == null) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed('name is required');
          }
          final current = e.record.strokeMap?['color'];
          final r = await showIconPicker(
            dc,
            services: ed.services,
            theme: ElementStyle.themeOf(ed),
            initialName: data['name'] as String?,
            strokeWidth: stroke,
            color: current is String ? current : null,
            replace: true,
          );
          if (r == null) return const CommandResult.cancelled();
          name = r.name;
          if (r.strokeWidth != stroke || r.color != current) {
            final next = ElementStyle.merge(e.record.strokeMap, {
              'color': r.color,
            })..remove('v');
            ed.apply(
              ctx,
              SetElementProps(
                [e.id],
                strokeJson: Patch(
                  next.isEmpty ? null : ElementStyle.encode(next),
                ),
              ),
            );
          }
          ed.apply(
            ctx,
            SetElementData(
              e.id,
              jsonEncode({
                'v': 1,
                'set': 'lucide',
                'name': LucideCatalog.of(name)!.name,
                'strokeWidth': r.strokeWidth,
              }),
            ),
          );
          return ok();
        }
        final icon = LucideCatalog.of(name);
        if (icon == null) return CommandResult.failed('Unknown icon $name');
        ed.apply(
          ctx,
          SetElementData(
            e.id,
            jsonEncode({
              'v': 1,
              'set': 'lucide',
              'name': icon.name,
              'strokeWidth': LucideGlyphs.snapStrokeWidth(stroke),
            }),
          ),
        );
        return ok();
      },
    ),
    SlidesCommand(
      'slides.icon.setStrokeWidth',
      label: (l) => l.cmdIconSetStrokeWidth,
      icon: LucideIcons.penLine,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'value': JsonSchema.number(minimum: 1, maximum: 3),
          'ids': JsonSchema.array(JsonSchema.string()),
        },
        required: ['value'],
      ),
      enabled: (ed, a) => _lucideIcons(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectIcon,
      checked: (ed, a) {
        final icons = _lucideIcons(ed, a);
        final v = _num(a, 'value');
        if (icons.isEmpty || v == null) return null;
        return icons.every(
          (e) =>
              LucideGlyphs.snapStrokeWidth(e.data?['strokeWidth'] as num?) ==
              LucideGlyphs.snapStrokeWidth(v),
        );
      },
      run: (ctx, ed, a) {
        final w = LucideGlyphs.snapStrokeWidth(_num(a, 'value'));
        for (final e in _lucideIcons(ed, a)) {
          ed.apply(
            ctx,
            SetElementData(e.id, jsonEncode({...?e.data, 'strokeWidth': w})),
          );
        }
        return ok();
      },
    ),

    // ---- Element groups (03 §7)
    SlidesCommand(
      'slides.arrange.group',
      label: (l) => l.cmdArrangeGroup,
      icon: LucideIcons.group,
      categoryOf: SlidesCategory.arrange,
      mutates: true,
      keyScope: SlidesKeyScopes.canvas,
      defaultBindings: const [
        KeyBinding('G', mod: true),
        KeyBinding('G', mod: true, alt: true),
      ],
      argsSchema: const JsonSchema.object(
        properties: {'ids': JsonSchema.array(JsonSchema.string())},
      ),
      enabled: (ed, a) => _groupBlock(ed, a) == null,
      reason: (l, ed) => switch (_groupBlock(ed, const JsonArgs())) {
        _GroupBlock.placeholder => l.reasonPlaceholdersCantGroup,
        _GroupBlock.level => l.reasonSameLevel,
        _ => l.reasonSelectTwoObjects,
      },
      run: (ctx, ed, a) {
        final ids = _ids(ed, a);
        final entered = selectionOf(ed).enteredGroupId;
        final plan = ed.apply(ctx, GroupElements(ids));
        final gid = plan.result['groupId'];
        if (gid is String) {
          selectionOf(ed).select([gid], enteredGroup: entered);
        }
        return ok({'groupId': gid});
      },
    ),
    SlidesCommand(
      'slides.arrange.ungroup',
      label: (l) => l.cmdArrangeUngroup,
      icon: LucideIcons.ungroup,
      categoryOf: SlidesCategory.arrange,
      mutates: true,
      keyScope: SlidesKeyScopes.canvas,
      defaultBindings: const [
        KeyBinding('G', mod: true, shift: true),
        KeyBinding('G', mod: true, alt: true, shift: true),
      ],
      argsSchema: const JsonSchema.object(
        properties: {'ids': JsonSchema.array(JsonSchema.string())},
      ),
      enabled: (ed, a) => _ofKind(ed, a, ElementKind.group).isNotEmpty,
      reason: (l, ed) => l.reasonSelectGroup,
      run: (ctx, ed, a) {
        final groups = [
          for (final g in _ofKind(ed, a, ElementKind.group)) g.id,
        ];
        final entered = selectionOf(ed).enteredGroupId;
        final plan = ed.apply(ctx, UngroupElements(groups));
        final ids = plan.result['elementIds'];
        if (ids is List) {
          selectionOf(
            ed,
          ).select(ids.whereType<String>(), enteredGroup: entered);
        }
        for (final w in plan.warnings) {
          if (!ctx.source.isAgent) ed.services.toasts.show(w);
        }
        return ok({'elementIds': ids, 'warnings': plan.warnings});
      },
    ),

    // ---- Accessibility and names (03 §17.1, §8.1)
    SlidesCommand(
      'slides.element.editAltText',
      label: (l) => l.cmdElementEditAltText,
      icon: LucideIcons.captions,
      categoryOf: SlidesCategory.format,
      mutates: true,
      defaultBindings: const [KeyBinding('Y', mod: true, alt: true)],
      keyScope: SlidesKeyScopes.canvas,
      argsSchema: const JsonSchema.object(
        properties: {
          'altText': JsonSchema.string(),
          'decorative': JsonSchema.boolean(),
          'ids': JsonSchema.array(JsonSchema.string()),
        },
      ),
      enabled: (ed, a) => _ids(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectObject,
      run: (ctx, ed, a) async {
        final ids = _ids(ed, a);
        var alt = a.string('altText');
        var decorative = a.boolean('decorative');
        if (alt == null && decorative == null) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed(
              'altText or decorative is required',
            );
          }
          final e = ed.model.element(ids.first);
          final r = await showAltTextDialog(
            dc,
            altText: e?.altText ?? '',
            decorative: e?.decorative ?? false,
          );
          if (r == null) return const CommandResult.cancelled();
          (alt, decorative) = r;
        }
        ed.apply(
          ctx,
          SetElementProps(
            ids,
            altText: alt == null ? null : Patch(alt.isEmpty ? null : alt),
            decorative: decorative,
          ),
        );
        return ok();
      },
    ),
    SlidesCommand(
      'slides.element.rename',
      label: (l) => l.cmdElementRename,
      icon: LucideIcons.pencil,
      categoryOf: SlidesCategory.arrange,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'name': JsonSchema.string(description: 'Empty = generated name.'),
          'id': JsonSchema.string(),
        },
        required: ['name'],
      ),
      enabled: (ed, a) =>
          a.string('id') != null || ed.selectedElementIds.length == 1,
      reason: (l, ed) => l.reasonSelectOneObject,
      run: (ctx, ed, a) {
        final id = a.string('id') ?? ed.selectedElementIds.single;
        final name = a.requireString('name').trim();
        ed.apply(
          ctx,
          SetElementProps([id], elementName: Patch(name.isEmpty ? null : name)),
        );
        return ok();
      },
    ),
  ];
}

String _lastShape = 'rect';
(String, String) _lastLine = ('straight', 'none');

const _endpointSchema = JsonSchema.object(
  properties: {
    'x': JsonSchema.number(),
    'y': JsonSchema.number(),
    'elementId': JsonSchema.string(description: 'Glue to this element.'),
    'site': JsonSchema.string(description: 'Connection site of elementId.'),
  },
  required: ['x', 'y'],
);

double? _num(JsonArgs a, String key) => (a.values[key] as num?)?.toDouble();

List<String> _ids(DeckEditorController ed, JsonArgs a) {
  final raw = a.values['ids'];
  if (raw is List) return raw.whereType<String>().toList();
  return ed.selectedElementIds;
}

/// The targets of [a] (`ids` or the selection) of [kind].
List<ResolvedElement> _ofKind(
  DeckEditorController ed,
  JsonArgs a,
  ElementKind kind,
) => [
  for (final e in ElementStyle.targets(
    ed,
    a.values['ids'] is List ? _ids(ed, a) : null,
  ))
    if (e.record.kind == kind) e,
];

ResolvedElement? _icon(DeckEditorController ed, JsonArgs a) {
  final id = a.string('id');
  final ids = id != null ? [id] : ed.selectedElementIds;
  if (ids.length != 1) return null;
  final els = ElementStyle.targets(ed, ids);
  return els.length == 1 && els.single.record.kind == ElementKind.icon
      ? els.single
      : null;
}

List<ResolvedElement> _lucideIcons(DeckEditorController ed, JsonArgs a) => [
  for (final e in _ofKind(ed, a, ElementKind.icon))
    if (e.data?['set'] != 'emoji') e,
];

/// The selected icon a double-click / Enter replaces (03 §6.7), or null.
ResolvedElement? activatableIcon(DeckEditorController ed) =>
    _icon(ed, const JsonArgs());

enum _GroupBlock { count, placeholder, level }

_GroupBlock? _groupBlock(DeckEditorController ed, JsonArgs a) {
  final ids = _ids(ed, a);
  if (ids.length < 2) return _GroupBlock.count;
  final els = selectionOf(ed).elements;
  if (els == null) return _GroupBlock.count;
  final parents = <String?>{};
  for (final id in ids) {
    final e = els[id];
    if (e == null) return _GroupBlock.count;
    if (e.placeholderType != null) return _GroupBlock.placeholder;
    parents.add(els.parentOf(id)?.id);
  }
  return parents.length == 1 ? null : _GroupBlock.level;
}

(double, double) _slideSize(DeckEditorController ed) {
  final d = ed.model.deck;
  return (d?.width ?? 1920, d?.height ?? 1080);
}

/// A [w] × [h] box at ([x], [y]), or centered on the slide.
(double, double, double, double) _placed(
  DeckEditorController ed,
  double? x,
  double? y,
  double w,
  double h,
) {
  final (sw, sh) = _slideSize(ed);
  return (x ?? (sw - w) / 2, y ?? (sh - h) / 2, math.max(w, 1), math.max(h, 1));
}

/// Inserts [spec] on the current slide (top level), selects it and
/// returns to the Select tool.
CommandResult _insert(
  CommandContext ctx,
  DeckEditorController ed,
  ElementSpec spec,
) {
  final slide = ed.surfaceId;
  if (slide == null) return const CommandResult.failed('No slide');
  final plan = ed.apply(
    ctx,
    InsertElements(slide, [spec], ownerKind: ed.surfaceKind),
  );
  final ids = plan.result['elementIds'];
  ed.armTool(null);
  if (ids is List && ids.isNotEmpty) {
    selectionOf(ed).select(ids.whereType<String>());
    ed.canvasFocus.requestFocus();
  }
  return ok({'elementId': ids is List && ids.isNotEmpty ? ids.first : null});
}

void _announce(
  CommandContext ctx,
  DeckEditorController ed,
  String Function(SlidesLocalizations l) text,
) {
  final bc = ctx.buildContext;
  if (bc == null || !bc.mounted) return;
  unawaited(
    SemanticsService.sendAnnouncement(
      View.of(bc),
      text(slidesL10nOf(ed.services)),
      Directionality.of(bc),
    ),
  );
}

/// Element records' `strokeJson` as a map.
extension on SlideElementRec {
  Map<String, Object?>? get strokeMap =>
      ElementStyle.decode(str(ElementCols.strokeJson));
}
