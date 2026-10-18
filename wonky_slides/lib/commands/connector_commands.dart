import 'dart:convert';

import 'package:flutter/widgets.dart' show Offset;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/scene.dart' show ConnectorRouter, LineRouting;

import '../features/canvas/canvas_interactions.dart';
import '../features/canvas/slide_canvas_controller.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/elements/line/connector_handles.dart';
import '../l10n/slides_l10n.dart' show slidesL10nOf;
import 'slides_command.dart';

/// Connector route editing (Slides 03 §6.4, SL-44): the segment handles of
/// elbow connectors and the bend handle of curved ones write
/// `slides.line.setWaypoints`; registers the canvas handles.
List<Command<CommandArgs>> connectorCommands(ShellServices s) {
  CanvasInteractions.register(ConnectorHandles.new);
  ConnectorHandles.commit = _commitFromCanvas;
  return [
    SlidesCommand(
      'slides.line.setWaypoints',
      label: (l) => l.cmdLineSetWaypoints,
      icon: LucideIcons.spline,
      categoryOf: SlidesCategory.format,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'id': JsonSchema.string(description: 'The connector.'),
          'waypoints': JsonSchema.array(
            JsonSchema.object(
              properties: {
                'x': JsonSchema.number(description: 'Slide x (su).'),
                'y': JsonSchema.number(description: 'Slide y (su).'),
              },
              required: ['x', 'y'],
            ),
            description:
                'Elbow: the corners the route runs through; curved: one '
                'bend point the curve passes at its middle; [] resets the '
                'automatic route.',
          ),
        },
        required: ['id', 'waypoints'],
      ),
      run: (ctx, ed, a) {
        final raw = a.values['waypoints'];
        if (raw is! List) {
          return const CommandResult.failed('waypoints is required');
        }
        final points = <Offset>[];
        for (final p in raw) {
          if (p is! Map || p['x'] is! num || p['y'] is! num) {
            return const CommandResult.failed('Each waypoint needs x and y');
          }
          points.add(
            Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()),
          );
        }
        return setLineWaypoints(ctx, ed, a.requireString('id'), points);
      },
    ),
  ];
}

Future<void> _commitFromCanvas(
  SlideCanvasController c,
  String lineId,
  List<Offset> waypoints,
) => c.editor.invokeCommand('slides.line.setWaypoints', {
  'id': lineId,
  'waypoints': [
    for (final p in waypoints) {'x': _round(p.dx), 'y': _round(p.dy)},
  ],
});

/// Writes [waypoints] (slide su) of top-level line [id]: the frame becomes
/// the box of the route's current endpoints and the waypoints (rotation
/// and flips cleared, like moving an endpoint), the endpoints keep their
/// glue and are stored at their current positions, the waypoints are
/// normalized in the frame (02 §6.3) — one undo step.
CommandResult setLineWaypoints(
  CommandContext ctx,
  DeckEditorController ed,
  String id,
  List<Offset> waypoints,
) {
  final rec = ed.model.element(id);
  if (rec == null || rec.kind != ElementKind.line) {
    return const CommandResult.failed('Not a line');
  }
  if (rec.locked) {
    return CommandResult.failed(slidesL10nOf(ed.services).errorObjectLocked);
  }
  final els = selectionOf(ed).elements;
  final line = els?[id];
  if (line == null) {
    return CommandResult.failed(slidesL10nOf(ed.services).errorLineNotOnSlide);
  }
  if (line.parentId != null) {
    return CommandResult.failed(
      slidesL10nOf(ed.services).errorRouteHandlesInGroups,
    );
  }
  final data = line.data ?? const <String, Object?>{};
  final routing = LineRouting.fromName(data['routing']);
  if (routing == LineRouting.straight && waypoints.isNotEmpty) {
    return CommandResult.failed(
      slidesL10nOf(ed.services).errorStraightLineWaypoints,
    );
  }
  if (routing == LineRouting.curved && waypoints.length > 1) {
    return const CommandResult.failed('A curved connector bends once');
  }
  final route = ConnectorRouter.route(line, (x) => els?[x]);
  final s = Offset(route.start.x, route.start.y);
  final e = Offset(route.end.x, route.end.y);
  final all = [s, e, ...waypoints];
  final x0 = all.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
  final y0 = all.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
  final x1 = all.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
  final y1 = all.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
  final w = x1 - x0, h = y1 - y0;
  double nx(double v) => w == 0 ? 0 : _round((v - x0) / w);
  double ny(double v) => h == 0 ? 0 : _round((v - y0) / h);
  Map<String, Object?> end(String key, Offset p) {
    final old = data[key];
    return {
      if (old is Map) ...old.cast<String, Object?>(),
      'x': nx(p.dx),
      'y': ny(p.dy),
    };
  }

  ed.apply(
    ctx,
    UpdateFrames([
      FrameUpdate(
        id,
        x: x0,
        y: y0,
        width: w,
        height: h,
        rotation: 0,
        flipH: false,
        flipV: false,
      ),
    ], label: 'Edit connector'),
  );
  ed.apply(
    ctx,
    SetElementData(
      id,
      jsonEncode({
        'v': 1,
        ...data,
        'start': end('start', s),
        'end': end('end', e),
        'waypoints': [
          for (final p in waypoints) [nx(p.dx), ny(p.dy)],
        ],
      }),
    ),
  );
  return ok();
}

double _round(double v) => (v * 1e6).roundToDouble() / 1e6;
