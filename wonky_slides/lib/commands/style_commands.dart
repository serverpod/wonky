import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/widgets.dart' show Directionality, Offset, View;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show ElementCols;

import '../features/canvas/slide_canvas_controller.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/elements/style/element_style.dart';
import '../features/elements/table/table_cells.dart';
import '../features/format_painter/format_painter.dart';
import '../l10n/slides_l10n.dart';
import 'slides_command.dart';

/// The style commands of SL-14 (Slides 02 §5.2–§5.4, 03 §9, 04 §4.5):
/// fill, border, effects and opacity of the selected objects (or `ids`),
/// *Paint format* (one-shot; a second click within 500 ms or `sticky`
/// keeps it armed until Esc) and *Copy style* / *Paste style*. Every
/// application is one undo step.
List<Command<CommandArgs>> styleCommands(ShellServices s) => [
  SlidesCommand(
    'slides.format.fill',
    label: (l) => l.cmdFormatFill,
    icon: LucideIcons.paintBucket,
    categoryOf: SlidesCategory.format,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'color': JsonSchema.nullable(
          JsonSchema.string(
            description:
                'Solid fill ColorRef (#RRGGBB, theme:accent1…); null resets '
                'to the theme default.',
          ),
        ),
        'fill': JsonSchema.object(
          description: 'A fillJson object (02 §5.2: solid, gradient, image).',
          additionalProperties: true,
        ),
        'none': JsonSchema.boolean(description: 'No fill.'),
        'ids': JsonSchema.array(JsonSchema.string()),
      },
    ),
    enabled: (ed, a) => _with(ed, a, ElementStyle.hasFill).isNotEmpty,
    reason: (l, ed) => l.reasonNoFill,
    run: (ctx, ed, a) {
      final targets = _with(ed, a, ElementStyle.hasFill);
      final Patch<String?> patch;
      if (a.boolean('none') ?? false) {
        patch = const Patch('{"v":1,"type":"none"}');
      } else if (a.values['fill'] is Map) {
        final f = (a.values['fill'] as Map).cast<String, Object?>()
          ..remove('v');
        final err = ElementStyle.fillError(f);
        if (err != null) return CommandResult.failed(err);
        patch = Patch(ElementStyle.encode(f));
      } else if (a.values.containsKey('color')) {
        final c = a.values['color'];
        if (c == null) {
          patch = const Patch(null);
        } else {
          if (!ElementStyle.validColor(c)) {
            return CommandResult.failed('Invalid color $c');
          }
          patch = Patch(ElementStyle.encode({'type': 'solid', 'color': c}));
        }
      } else {
        return _openSection(ctx, ed, 'fill');
      }
      ed.apply(
        ctx,
        SetElementProps([for (final e in targets) e.id], fillJson: patch),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.format.stroke',
    label: (l) => l.cmdFormatStroke,
    icon: LucideIcons.square,
    categoryOf: SlidesCategory.format,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'color': JsonSchema.string(description: 'ColorRef.'),
        'width': JsonSchema.number(minimum: 0, maximum: 100),
        'dash': JsonSchema.string(
          enumValues: ['solid', 'dash', 'dot', 'dashDot', 'longDash'],
        ),
        'cap': JsonSchema.string(enumValues: ['butt', 'round', 'square']),
        'join': JsonSchema.string(enumValues: ['miter', 'round', 'bevel']),
        'none': JsonSchema.boolean(description: 'No border.'),
        'reset': JsonSchema.boolean(description: 'Back to the theme style.'),
        'ids': JsonSchema.array(JsonSchema.string()),
      },
    ),
    enabled: (ed, a) => _with(ed, a, ElementStyle.hasStroke).isNotEmpty,
    reason: (l, ed) => l.reasonNoBorder,
    run: (ctx, ed, a) {
      final targets = _with(ed, a, ElementStyle.hasStroke);
      const keys = ['color', 'width', 'dash', 'cap', 'join'];
      final reset = a.boolean('reset') ?? false;
      final none = a.boolean('none') ?? false;
      if (!reset && !none && !keys.any(a.values.containsKey)) {
        return _openSection(ctx, ed, 'border');
      }
      final color = a.values['color'];
      if (color != null && !ElementStyle.validColor(color)) {
        return CommandResult.failed('Invalid color $color');
      }
      for (final e in targets) {
        final String? next;
        if (reset) {
          next = null;
        } else if (none) {
          // Lines keep their arrowheads' settings for when a border returns.
          next = ElementStyle.encode({'type': 'none'});
        } else {
          final base = ElementStyle.decode(
            e.record.str(ElementCols.strokeJson),
          );
          final merged = ElementStyle.merge(
            base?['type'] == 'none' ? (base!..remove('type')) : base,
            {
              for (final k in keys)
                if (a.values.containsKey(k)) k: a.values[k],
            },
          )..remove('v');
          final err = ElementStyle.strokeError(merged);
          if (err != null) return CommandResult.failed(err);
          next = merged.isEmpty ? null : ElementStyle.encode(merged);
        }
        ed.apply(ctx, SetElementProps([e.id], strokeJson: Patch(next)));
      }
      return ok();
    },
  ),
  SlidesCommand(
    'slides.format.effects',
    label: (l) => l.cmdFormatEffects,
    icon: LucideIcons.sparkle,
    categoryOf: SlidesCategory.format,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'shadow': JsonSchema.any(
          description:
              'true = the theme shadow, false = none, or {color, blur, dx, '
              'dy, spread}.',
        ),
        'glow': JsonSchema.any(
          description: 'true = accent glow, false = none, or {color, radius}.',
        ),
        'blur': JsonSchema.number(minimum: 0, maximum: 100),
        'reset': JsonSchema.boolean(description: 'Remove every effect.'),
        'ids': JsonSchema.array(JsonSchema.string()),
      },
    ),
    enabled: (ed, a) => _targets(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    run: (ctx, ed, a) {
      final targets = _targets(ed, a);
      final v = a.values;
      if (!(a.boolean('reset') ?? false) &&
          !v.containsKey('shadow') &&
          !v.containsKey('glow') &&
          !v.containsKey('blur')) {
        return _openSection(ctx, ed, 'effects');
      }
      final theme = ElementStyle.themeOf(ed);
      Object? shadow(Object? s) => switch (s) {
        true =>
          theme?.shapeStyles.shadow?.toJson() ??
              const {
                'color': '#00000040',
                'blur': 24,
                'dx': 0,
                'dy': 12,
                'spread': 0,
              },
        false || null => null,
        final Map<Object?, Object?> m => m.cast<String, Object?>(),
        _ => throw const FormatException('shadow'),
      };
      Object? glow(Object? g) => switch (g) {
        true => const {'color': 'theme:accent1/alpha:0.6', 'radius': 16},
        false || null => null,
        final Map<Object?, Object?> m => m.cast<String, Object?>(),
        _ => throw const FormatException('glow'),
      };
      final Map<String, Object?> patch;
      try {
        patch = {
          if (v.containsKey('shadow')) 'shadow': shadow(v['shadow']),
          if (v.containsKey('glow')) 'glow': glow(v['glow']),
          if (v.containsKey('blur'))
            'blur': (v['blur'] as num?) == 0 ? null : v['blur'],
        };
      } on FormatException catch (e) {
        return CommandResult.failed('Invalid ${e.message}');
      }
      for (final e in targets) {
        final String? next;
        if (a.boolean('reset') ?? false) {
          next = null;
        } else {
          final m = ElementStyle.merge(
            ElementStyle.decode(e.record.str(ElementCols.effectsJson)),
            patch,
          )..remove('v');
          next = m.isEmpty ? null : ElementStyle.encode(m);
        }
        ed.apply(ctx, SetElementProps([e.id], effectsJson: Patch(next)));
      }
      return ok();
    },
  ),
  SlidesCommand(
    'slides.format.opacity',
    label: (l) => l.cmdFormatOpacity,
    icon: LucideIcons.blend,
    categoryOf: SlidesCategory.format,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'value': JsonSchema.number(minimum: 0, maximum: 1),
        'ids': JsonSchema.array(JsonSchema.string()),
      },
    ),
    enabled: (ed, a) => _targets(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    run: (ctx, ed, a) {
      final v = (a.values['value'] as num?)?.toDouble();
      if (v == null) return _openSection(ctx, ed, 'effects');
      final o = v.clamp(0, 1).toDouble();
      ed.apply(
        ctx,
        SetElementProps([
          for (final e in _targets(ed, a)) e.id,
        ], opacity: Patch(o >= 1 ? null : o)),
      );
      return ok();
    },
  ),

  // ---- Format painter and style clipboard (03 §9)
  SlidesCommand(
    'slides.format.paintFormat',
    label: (l) => l.cmdFormatPaintFormat,
    icon: LucideIcons.paintbrush,
    categoryOf: SlidesCategory.format,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'sticky': JsonSchema.boolean(
          description: 'Stay armed after applying (until Esc).',
        ),
        'targetIds': JsonSchema.array(
          JsonSchema.string(),
          description: 'Apply the armed style to these objects.',
        ),
        'x': JsonSchema.number(
          description: 'Clicked point (su): picks the cell of a table.',
        ),
        'y': JsonSchema.number(),
      },
    ),
    checked: (ed, a) => FormatPainter.armed(ed),
    enabled: (ed, a) =>
        FormatPainter.armed(ed) ||
        ed.selectedElementIds.isNotEmpty ||
        a.strings('targetIds').isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    run: (ctx, ed, a) {
      final painter = FormatPainter.of(ed);
      final targets = a.strings('targetIds');
      if (targets.isNotEmpty) {
        final style = painter.paint;
        if (style == null || !FormatPainter.armed(ed)) {
          return const CommandResult.failed('Paint format is not armed');
        }
        final x = a.values['x'], y = a.values['y'];
        _applyStyle(
          ctx,
          ed,
          style,
          targets,
          at: x is num && y is num ? Offset(x.toDouble(), y.toDouble()) : null,
        );
        if (!painter.sticky) _disarm(ed);
        selectionOf(ed).select(targets);
        return ok();
      }
      final sticky = a.boolean('sticky');
      final now = clock.now();
      if (FormatPainter.armed(ed)) {
        if (sticky ?? false) {
          painter.sticky = true;
          return ok({'sticky': true});
        }
        // A second click within the double-click time keeps it armed.
        final at = painter.armedAt;
        if (!painter.sticky &&
            at != null &&
            now.difference(at) < const Duration(milliseconds: 500)) {
          painter.sticky = true;
          return ok({'sticky': true});
        }
        _disarm(ed);
        return ok({'armed': false});
      }
      final source = ElementStyle.targets(ed).firstOrNull;
      if (source == null) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).reasonSelectObject,
        );
      }
      painter
        ..paint = ElementStylePayload.captureIn(ed, source)
        ..sticky = sticky ?? false
        ..armedAt = now;
      ed.armTool(FormatPainter.toolName);
      _announce(ctx, ed, (l) => l.painterArmed);
      return ok({'armed': true, 'sticky': painter.sticky});
    },
  ),
  SlidesCommand(
    'slides.format.copyStyle',
    label: (l) => l.cmdFormatCopyStyle,
    icon: LucideIcons.clipboardCopy,
    categoryOf: SlidesCategory.format,
    defaultBindings: const [KeyBinding('C', mod: true, alt: true)],
    keyScope: SlidesKeyScopes.canvas,
    enabled: (ed, a) => ed.selectedElementIds.isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    run: (ctx, ed, a) {
      final source = ElementStyle.targets(ed).firstOrNull;
      if (source == null) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).reasonSelectObject,
        );
      }
      final style = ElementStylePayload.captureIn(ed, source);
      FormatPainter.of(ed).clipboard = style;
      return ok({'style': style.toJson()});
    },
  ),
  SlidesCommand(
    'slides.format.pasteStyle',
    label: (l) => l.cmdFormatPasteStyle,
    icon: LucideIcons.clipboardPaste,
    categoryOf: SlidesCategory.format,
    mutates: true,
    defaultBindings: const [KeyBinding('V', mod: true, alt: true)],
    keyScope: SlidesKeyScopes.canvas,
    argsSchema: const JsonSchema.object(
      properties: {
        'style': JsonSchema.object(
          description:
              'A style from slides.format.copyStyle (else the '
              'copied one).',
          additionalProperties: true,
        ),
        'ids': JsonSchema.array(JsonSchema.string()),
      },
    ),
    enabled: (ed, a) =>
        (FormatPainter.of(ed).clipboard != null || a.values['style'] != null) &&
        _targets(ed, a).isNotEmpty,
    reason: (l, ed) => FormatPainter.of(ed).clipboard == null
        ? l.reasonNoStyleCopied
        : l.reasonSelectObject,
    run: (ctx, ed, a) {
      final style =
          ElementStylePayload.fromJson(a.values['style']) ??
          FormatPainter.of(ed).clipboard;
      if (style == null) {
        return const CommandResult.failed('Copy a style first');
      }
      _applyStyle(ctx, ed, style, [for (final e in _targets(ed, a)) e.id]);
      return ok();
    },
  ),
];

List<String>? _idsArg(JsonArgs a) {
  final raw = a.values['ids'];
  return raw is List ? raw.whereType<String>().toList() : null;
}

List<ResolvedElement> _targets(DeckEditorController ed, JsonArgs a) =>
    ElementStyle.targets(ed, _idsArg(a));

List<ResolvedElement> _with(
  DeckEditorController ed,
  JsonArgs a,
  bool Function(ElementKind) supports,
) => [
  for (final e in _targets(ed, a))
    if (supports(e.record.kind)) e,
];

void _applyStyle(
  CommandContext ctx,
  DeckEditorController ed,
  ElementStylePayload style,
  List<String> ids, {
  Offset? at,
}) {
  final targets = ElementStyle.targets(ed, ids);
  // A table-cell style goes onto cells (SL-15, 03 §9): the clicked cell,
  // else the cell selection, else every cell.
  final cellStyle = style.cell != null;
  for (final t in targets) {
    if (t.record.kind != ElementKind.table || !cellStyle) continue;
    final ix = ed.model.indexes.table(t.id);
    final canvas = SlideCanvasController.of(ed);
    final hit = at == null || canvas == null
        ? null
        : TableGeometry.cellAt(canvas, t.id, at);
    final sel = TableCellSelection.of(ed);
    final range = hit != null
        ? TableRange.spanning(ix, hit.row, hit.column, hit.row, hit.column)
        : (sel.tableId == t.id ? sel.range : null) ?? TableRange.all(ix);
    final cells = <({String rowId, String columnId})>[
      if (range != null)
        for (final c in range.cells(ix)) (rowId: c.rowId, columnId: c.columnId),
    ];
    for (final op in style.cellOpsFor(t.id, cells, ix)) {
      ed.apply(ctx, op);
    }
  }
  if (cellStyle) return;
  for (final op in style.opsFor(targets)) {
    ed.apply(ctx, op);
  }
}

void _disarm(DeckEditorController ed) {
  final p = FormatPainter.of(ed)
    ..paint = null
    ..sticky = false
    ..armedAt = null;
  assert(p.paint == null);
  if (FormatPainter.armed(ed)) ed.armTool(null);
}

/// *Fill…*, *Border…*, *Effects…* and *Opacity…* without values open the
/// inspector's Format section (04 §4.5).
CommandResult _openSection(
  CommandContext ctx,
  DeckEditorController ed,
  String section,
) {
  if (ctx.source.isAgent) {
    return const CommandResult.failed('A value is required');
  }
  ed.openInspector(InspectorTab.format, section: section);
  return ok({'section': section});
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
