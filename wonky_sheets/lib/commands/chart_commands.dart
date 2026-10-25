import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart'
    hide showChartDataTableDialog;

import '../features/charts/chart_insert.dart';
import '../features/charts/view/chart_data_table_dialog.dart';
import 'package:wonky_app/platform.dart' show ImageClipboard;
import '../features/images/image_io.dart';
import '../features/images/image_service.dart';
import '../features/objects/object_ops.dart';
import '../features/objects/object_png.dart';
import '../features/objects/objects_controller.dart';
import '../features/objects/objects_layer.dart' show objectKeyScope;
import '../features/sheet_editor/sheet_editor_controller.dart';
import 'sheets_command.dart';

SheetsText _cat = (l) => l.categoryCharts;

ObjectsController _objs(SheetEditorController ed) => ObjectsController.of(ed);

EmbeddedObjectRecord? _chart(SheetEditorController ed, JsonArgs a) {
  final o = ObjectOps.target(ed, a.values);
  return o?.kind == EmbeddedObjectKind.chart ? o : null;
}

bool _isChart(SheetEditorController ed, JsonArgs a) => _chart(ed, a) != null;

bool _editableChart(SheetEditorController ed, JsonArgs a) {
  final o = _chart(ed, a);
  return o != null && !ChartSpec.fromJson(o.specJson).isFromNewerVersion;
}

String _missing(SheetEditorController ed) => ed.l10n.chartNotFound;

const _idProp = JsonSchema.string(
  description: 'Chart object id (default: the selected chart).',
);

/// Writes [spec] to chart [o]; with [coalesceKey], consecutive edits of the
/// same field within 1000 ms are one undo step (08 §8).
void _writeSpec(
  CommandContext ctx,
  SheetEditorController ed,
  EmbeddedObjectRecord o,
  ChartSpec spec, {
  String? coalesceKey,
}) {
  final op = UpdateObject(o.id, specJson: spec.encode());
  if (coalesceKey == null) {
    ed.apply(ctx, op);
    return;
  }
  final plan = ed.session.execute(op);
  ObjectOps.recordCoalesced(
    ctx,
    ed,
    plan,
    key: 'chart:${o.id}:$coalesceKey',
    label: ed.l10n.undoEditChart,
  );
}

/// The chart commands (08 §16).
List<Command<CommandArgs>> chartCommands(ShellServices s) => [
  SheetsCommand(
    'sheets.chart.insert',
    label: (l) => l.cmdChartInsert,
    icon: LucideIcons.chartColumn,
    categoryName: _cat,
    mutates: true,
    descriptionText: (l) => l.cmdChartInsertDescription,
    argsSchema: JsonSchema.object(
      properties: {
        'ranges': const JsonSchema.array(
          JsonSchema.string(),
          description: 'A1 data ranges (default: the selection).',
        ),
        'type': JsonSchema.string(
          enumValues: [
            for (final t in ChartType.values)
              if (t.isImplemented) t.id,
          ],
        ),
        'spec': const JsonSchema.object(
          description: 'A full ChartSpec (data.ranges may be A1 strings).',
          additionalProperties: true,
        ),
        'anchor': const JsonSchema.object(
          description: '{cell: A1, dx, dy, width, height} (px at 100 %).',
          additionalProperties: true,
        ),
      },
    ),
    enabled: (ed, a) => ed.activeSheet?.record?.kind != SheetKind.chart,
    run: (ctx, ed, a) {
      final sheet = ed.activeSheet!;
      ChartSpec spec;
      final rawSpec = a.values['spec'];
      final type = ChartType.tryParse(a.string('type'));
      if (rawSpec is Map) {
        spec = ChartSpec.parseStrict(
          ChartInsert.rangesToStored(ed, rawSpec.cast<String, Object?>()),
        );
      } else {
        final texts = a.strings('ranges');
        final ranges = texts.isEmpty
            ? ChartInsert.rangesFromSelection(ed)
            : ChartInsert.rangesFromA1(ed, texts);
        spec = ChartInsert.specFor(ed, ranges, type: type);
      }
      ObjectAnchor anchor;
      if (a.values['anchor'] case final Map<dynamic, dynamic> m) {
        final cell = ed.model.parseA1(
          '${m['cell'] ?? 'A1'}',
          contextSheetId: sheet.id,
        );
        anchor = ObjectAnchor.atCell(
          cell.rect.top,
          cell.rect.left,
          width: _num(m['width'], ObjectAnchor.defaultChartWidth),
          height: _num(m['height'], ObjectAnchor.defaultChartHeight),
          rows: sheet.rows,
          columns: sheet.columns,
          dx: _num(m['dx'], 0),
          dy: _num(m['dy'], 0),
        );
      } else {
        final region = ChartInsert.regionOf(ed, spec.data.gridRanges);
        final sel = ed.selection.resolved;
        anchor = ObjectPlacement.defaultChartAnchor(
          dataRegion: region ?? GridRect.cell(sel.activeRow, sel.activeCol),
          rows: sheet.rows,
          columns: sheet.columns,
          viewport: ObjectOps.viewport(ed),
          frozenRows: sheet.record?.frozenRows ?? 0,
          frozenColumns: sheet.record?.frozenColumns ?? 0,
        );
      }
      final plan = ed.apply(
        ctx,
        AddObject(
          sheet.id,
          EmbeddedObjectKind.chart,
          anchorJson: anchor.encode(),
          specJson: spec.encode(),
        ),
      );
      final id = plan.result['objectId']! as String;
      _objs(ed).select(id);
      if (rawSpec is! Map && ctx.source != InvocationSource.mcp) {
        ed.services.panels.open(chartEditorPanelId);
      }
      return ok({'objectId': id});
    },
  ),
  SheetsCommand(
    'sheets.chart.edit',
    label: (l) => l.cmdChartEdit,
    icon: LucideIcons.pencil,
    categoryName: _cat,
    keyScope: objectKeyScope,
    defaultBindings: const [KeyBinding('Enter')],
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': _idProp,
        'section': JsonSchema.string(
          description:
              'Customize section: style, titles, series, legend, hAxis, '
              'vAxis, gridlines, type (default: the Setup tab).',
        ),
        'seriesKey': JsonSchema.string(),
      },
    ),
    enabled: (ed, a) => ed.canEdit && _editableChart(ed, a),
    run: (ctx, ed, a) {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final objs = _objs(ed);
      if (o.sheetId != ed.activeSheetId) ed.activateSheet(o.sheetId);
      objs.select(o.id, focus: false);
      objs.editorJump.value = ChartEditorJump(
        section: a.string('section'),
        seriesKey: a.string('seriesKey'),
        serial: objs.editorJump.value.serial + 1,
      );
      ed.services.panels.open(chartEditorPanelId);
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.chart.update',
    label: (l) => l.cmdChartUpdate,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    undoLabelOf: (l, a) => l.undoEditChart,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': _idProp,
        'patch': JsonSchema.object(
          description: 'RFC 7386 JSON merge patch on the ChartSpec.',
          additionalProperties: true,
        ),
        'coalesceKey': JsonSchema.string(
          description: 'Edits of the same field within 1 s are one undo step.',
        ),
      },
      required: ['patch'],
    ),
    enabled: (ed, a) => _editableChart(ed, a),
    run: (ctx, ed, a) {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final patch = (a.values['patch']! as Map).cast<String, Object?>();
      // Read-modify-write on the latest local spec (08 §15.2).
      final spec = ChartSpec.fromJson(o.specJson);
      final ChartSpec next;
      try {
        next = spec.patch(ChartInsert.rangesToStored(ed, patch));
      } on ChartSpecValidationException catch (e) {
        return CommandResult.failed(e.issues.join('; '));
      }
      if (next.encode() == spec.encode()) return const CommandResult.ok();
      _writeSpec(ctx, ed, o, next, coalesceKey: a.string('coalesceKey'));
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.chart.setType',
    label: (l) => l.cmdChartSetType,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    undoLabelOf: (l, a) => l.undoEditChart,
    argsSchema: JsonSchema.object(
      properties: {
        'objectId': _idProp,
        'type': JsonSchema.string(
          enumValues: [
            for (final t in ChartType.values)
              if (t.isImplemented) t.id,
          ],
        ),
        'stacking': JsonSchema.string(
          enumValues: [for (final s in ChartStacking.values) s.name],
        ),
        'pieHole': const JsonSchema.number(),
        'smooth': const JsonSchema.boolean(description: 'Line: curved.'),
        'threeD': const JsonSchema.boolean(
          description: 'Column, bar, line, area, pie: draw in 3D.',
        ),
      },
      required: const ['type'],
    ),
    enabled: (ed, a) => _editableChart(ed, a),
    run: (ctx, ed, a) {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final type = ChartType.tryParse(a.string('type'));
      if (type == null || !type.isImplemented) {
        return const CommandResult.failed('Unknown chart type');
      }
      final stacking = ChartStacking.values
          .where((s) => s.name == a.string('stacking'))
          .firstOrNull;
      var next = ChartSpec.fromJson(
        o.specJson,
      ).withType(type, stacking: stacking ?? ChartStacking.none);
      final hole = a.values['pieHole'];
      if (type == ChartType.pie && hole is num) {
        next = next.copyWith(
          typeOptions: {...next.typeOptions, 'pieHole': hole.toDouble()},
        );
      } else if (type == ChartType.pie &&
          hole == null &&
          next.typeOptions.containsKey('pieHole') &&
          a.values.containsKey('pieHole')) {
        next = next.copyWith(
          typeOptions: {...next.typeOptions}..remove('pieHole'),
        );
      }
      final threeD = a.boolean('threeD');
      if (threeD != null && type.supports3D && threeD != next.threeD.enabled) {
        next = next.copyWith(threeD: next.threeD.copyWith(enabled: threeD));
      }
      final smooth = a.boolean('smooth');
      if (smooth != null && smooth != next.style.smooth) {
        next = next.patch({
          'style': {'smooth': smooth ? true : null},
        });
      }
      _writeSpec(ctx, ed, o, next);
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.chart.setDataRanges',
    label: (l) => l.cmdChartSetDataRanges,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    undoLabelOf: (l, a) => l.undoEditChart,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': _idProp,
        'ranges': JsonSchema.array(JsonSchema.string()),
        'keepSeries': JsonSchema.boolean(
          description: 'Keep the series/domain setup (default: re-detect).',
        ),
        'coalesceKey': JsonSchema.string(),
      },
      required: ['ranges'],
    ),
    enabled: (ed, a) => _editableChart(ed, a),
    run: (ctx, ed, a) {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final ranges = ChartInsert.rangesFromA1(ed, a.strings('ranges'));
      if (ranges.isEmpty) return const CommandResult.failed('No ranges');
      final spec = ChartSpec.fromJson(o.specJson);
      ChartSpec next;
      if (a.boolean('keepSeries') ?? false) {
        next = spec.copyWith(data: spec.data.copyWith(ranges: ranges.toRefs()));
      } else {
        final detected = ChartInsert.specFor(ed, ranges, type: spec.type);
        next = spec.copyWith(data: detected.data);
      }
      _writeSpec(ctx, ed, o, next, coalesceKey: a.string('coalesceKey'));
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.chart.download',
    label: (l) => l.cmdChartDownload,
    icon: LucideIcons.download,
    categoryName: _cat,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': _idProp,
        'format': JsonSchema.string(enumValues: ['png', 'svg', 'pdf']),
        'scale': JsonSchema.number(description: 'PNG scale 1, 2 or 4.'),
        'darkTheme': JsonSchema.boolean(),
      },
    ),
    enabled: (ed, a) {
      final o = ObjectOps.target(ed, a.values);
      if (o == null) return false;
      if (o.kind == EmbeddedObjectKind.image) return true;
      return o.kind == EmbeddedObjectKind.chart &&
          !ChartSpec.fromJson(o.specJson).isFromNewerVersion;
    },
    run: (ctx, ed, a) async {
      final o = ObjectOps.target(ed, a.values);
      if (o == null) return CommandResult.failed(_missing(ed));
      final l = ed.l10n;
      if (o.kind == EmbeddedObjectKind.image) {
        final spec = ImageSpec.fromJson(o.specJson);
        final src = spec.fileUuid.isNotEmpty
            ? spec.fileUuid
            : (spec.sourceUrl ?? '');
        final bytes = await SheetsImageService.of(ed).bytesForDownload(src);
        if (bytes == null) return CommandResult.failed(l.imageUnavailable);
        final local = SheetsImageService.of(ed).localBytes(spec.fileUuid);
        final mime = local != null ? spec.mime : 'image/png';
        final ext = switch (mime) {
          'image/jpeg' => 'jpg',
          'image/gif' => 'gif',
          'image/webp' => 'webp',
          _ => 'png',
        };
        final name = SheetsFileIo.safeName(o.title ?? 'Image', ext);
        await SheetsFileIo.saveBytes(name, bytes, mime, l);
        return ok({'fileName': name, 'bytes': bytes.length});
      }
      final format = a.string('format') ?? 'png';
      final dark = a.boolean('darkTheme') ?? false;
      final spec = ChartSpec.fromJson(o.specJson);
      final anchor = _objs(ed).anchorOf(o);
      var w = anchor?.width ?? ObjectAnchor.defaultChartWidth;
      var h = anchor?.height ?? ObjectAnchor.defaultChartHeight;
      if (w <= 0) w = ObjectAnchor.defaultChartWidth;
      if (h <= 0) h = ObjectAnchor.defaultChartHeight;
      final title = spec.title.text.trim().isNotEmpty
          ? spec.title.text.trim()
          : (o.title ?? 'Chart');
      final Uint8List bytes;
      final String mime;
      switch (format) {
        case 'svg':
          bytes = utf8.encode(
            SheetsChartPipeline.exportSvg(
              spec: spec,
              model: ed.model,
              values: ed.engine,
              size: ChartSize(w, h),
              dark: dark,
            ),
          );
          mime = 'image/svg+xml';
        case 'pdf':
          bytes = await SheetsChartPipeline.exportPdf(
            spec: spec,
            model: ed.model,
            values: ed.engine,
            size: ChartSize(w, h),
            dark: dark,
          );
          mime = 'application/pdf';
        default:
          final c = _objs(ed).chartOf(o);
          final scene = c.sceneFor(
            w,
            h,
            dark: dark,
            export: true,
            tokens: dark ? ChartUiTokens.dark : ChartUiTokens.light,
          );
          final scale = (a.values['scale'] as num?)?.toDouble() ?? 2;
          final png = await chartSceneToPng(scene, pixelRatio: scale);
          if (png == null) return const CommandResult.failed('PNG failed');
          bytes = png;
          mime = 'image/png';
      }
      final name = SheetsFileIo.safeName(
        title,
        format == 'svg' || format == 'pdf' ? format : 'png',
      );
      final saved = await SheetsFileIo.saveBytes(name, bytes, mime, l);
      if (!saved) return const CommandResult.cancelled();
      return ok({'fileName': name, 'bytes': bytes.length});
    },
  ),
  SheetsCommand(
    'sheets.chart.moveToOwnSheet',
    label: (l) => l.cmdChartMoveToOwnSheet,
    icon: LucideIcons.fileChartColumn,
    categoryName: _cat,
    mutates: true,
    argsSchema: const JsonSchema.object(properties: {'objectId': _idProp}),
    enabled: (ed, a) {
      final o = _chart(ed, a);
      return o != null &&
          ed.model.sheet(o.sheetId)?.record?.kind != SheetKind.chart;
    },
    run: (ctx, ed, a) {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final anchor = _objs(ed).anchorOf(o) ?? const ObjectAnchor();
      final specMap = (jsonDecode(o.specJson) as Map).cast<String, Object?>();
      final spec = ChartSpec.fromJson(specMap);
      final base = spec.title.text.trim().isNotEmpty
          ? spec.title.text.trim()
          : (o.title ?? 'Chart 1');
      final taken = {for (final s in ed.model.sheets) s.name.toLowerCase()};
      var name = base;
      for (var i = 2; taken.contains(name.toLowerCase()); i++) {
        name = '$base ($i)';
      }
      final order = ed.model.sheets.map((s) => s.id).toList();
      final at = order.indexOf(o.sheetId);
      final plan = ed.apply(
        ctx,
        AddSheet(
          name: name,
          index: at < 0 ? null : at + 1,
          rows: 1,
          columns: 1,
          kind: SheetKind.chart,
        ),
      );
      final sid = plan.result['sheetId']! as String;
      ed.apply(
        ctx,
        UpdateObject(
          o.id,
          sheetId: sid,
          anchorJson: anchor.toOwnSheet().encode(),
          specJson: jsonEncode(
            ChartSheetAnchors.withPreviousAnchor(specMap, anchor),
          ),
        ),
      );
      ed.activateSheet(sid);
      _objs(ed).select(o.id);
      return ok({'sheetId': sid});
    },
  ),
  SheetsCommand(
    'sheets.chart.moveToSheet',
    label: (l) => l.cmdChartMoveToSheet,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'objectId': _idProp, 'sheetId': JsonSchema.string()},
      required: ['sheetId'],
    ),
    enabled: (ed, a) {
      final o = _chart(ed, a);
      return o != null &&
          ed.model.sheet(o.sheetId)?.record?.kind == SheetKind.chart;
    },
    run: (ctx, ed, a) {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final target = ed.model.sheet(a.requireString('sheetId'));
      if (target == null || target.record?.kind == SheetKind.chart) {
        return const CommandResult.failed('Not a grid sheet');
      }
      final current = _objs(ed).anchorOf(o) ?? const ObjectAnchor();
      final specMap = (jsonDecode(o.specJson) as Map).cast<String, Object?>();
      final anchor = ChartSheetAnchors.anchorForMoveToSheet(
        spec: specMap,
        current: current,
        rows: target.rows,
        columns: target.columns,
      );
      final chartSheet = o.sheetId;
      ed.apply(
        ctx,
        UpdateObject(
          o.id,
          sheetId: target.id,
          anchorJson: anchor.encode(),
          specJson: jsonEncode(
            ChartSheetAnchors.withoutPreviousAnchor(specMap),
          ),
        ),
      );
      ed.apply(ctx, DeleteSheet(chartSheet));
      ed.activateSheet(target.id);
      _objs(ed).select(o.id);
      final rect = anchor.rectIn(target.rows, target.columns);
      if (rect != null) {
        ed.revealCell(
          target.rows.indexAtOffset(rect.top),
          target.columns.indexAtOffset(rect.left),
        );
      }
      return ok({'sheetId': target.id});
    },
  ),
  SheetsCommand(
    'sheets.chart.viewDataTable',
    label: (l) => l.cmdChartViewDataTable,
    icon: LucideIcons.table,
    categoryName: _cat,
    argsSchema: const JsonSchema.object(properties: {'objectId': _idProp}),
    enabled: (ed, a) => _isChart(ed, a),
    run: (ctx, ed, a) async {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final data = _objs(ed).chartOf(o).data;
      final c = ctx.dialogContext;
      if (c == null || ctx.source == InvocationSource.mcp) {
        return ok(chartDataJson(data));
      }
      await showChartDataTableDialog(c, title: o.title ?? '', data: data);
      return ok();
    },
  ),
  ..._chart3DCommands(),
  SheetsCommand(
    'sheets.chart.copyAsImage',
    label: (l) => l.cmdChartCopyAsImage,
    icon: LucideIcons.imageDown,
    categoryName: _cat,
    argsSchema: const JsonSchema.object(
      properties: {'objectId': _idProp, 'darkTheme': JsonSchema.boolean()},
    ),
    enabled: (ed, a) =>
        _editableChart(ed, a) && ImageClipboard.instance.supported,
    run: (ctx, ed, a) async {
      final o = _chart(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final png = await ObjectPng.of(
        ed,
        o,
        dark: a.boolean('darkTheme') ?? false,
      );
      if (png == null) return const CommandResult.failed('PNG failed');
      final done = await ImageClipboard.instance.writePng(png);
      if (!done) return CommandResult.failed(ed.l10n.chartCopyImageFailed);
      if (ctx.source != InvocationSource.mcp) {
        ed.services.toasts.show(ed.l10n.chartCopiedAsImage);
      }
      return ok({'objectId': o.id, 'bytes': png.length});
    },
  ),
];

double _num(Object? v, double fallback) => v is num ? v.toDouble() : fallback;

/// The selected chart if it can be drawn in 3D and edited.
EmbeddedObjectRecord? _chart3D(SheetEditorController ed, JsonArgs a) {
  final o = _chart(ed, a);
  if (o == null) return null;
  final spec = ChartSpec.fromJson(o.specJson);
  return spec.type.supports3D && !spec.isFromNewerVersion ? o : null;
}

/// 3D chart commands (08 §23.10): every change is one undo step.
List<Command<CommandArgs>> _chart3DCommands() => [
  SheetsCommand(
    'sheets.chart.toggle3D',
    label: (l) => l.cmdChartToggle3D,
    icon: LucideIcons.box,
    categoryName: _cat,
    mutates: true,
    descriptionText: (l) => l.cmdChartToggle3DDescription,
    undoLabelOf: (l, a) => l.undoEditChart,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': _idProp,
        'enabled': JsonSchema.boolean(
          description: 'On or off (default: toggle).',
        ),
      },
    ),
    enabled: (ed, a) {
      final o = _chart3D(ed, a);
      return o != null && !ChartSpec.fromJson(o.specJson).type.only3D;
    },
    run: (ctx, ed, a) {
      final o = _chart3D(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final spec = ChartSpec.fromJson(o.specJson);
      final on = a.boolean('enabled') ?? !spec.threeD.enabled;
      if (on == spec.threeD.enabled) return ok({'objectId': o.id});
      _writeSpec(
        ctx,
        ed,
        o,
        spec.copyWith(threeD: spec.threeD.copyWith(enabled: on)),
      );
      return ok({'objectId': o.id, 'threeD': on});
    },
  ),
  SheetsCommand(
    'sheets.chart.reset3DView',
    label: (l) => l.cmdChartReset3DView,
    icon: LucideIcons.rotateCcw,
    categoryName: _cat,
    mutates: true,
    undoLabelOf: (l, a) => l.undoEditChart,
    argsSchema: const JsonSchema.object(properties: {'objectId': _idProp}),
    enabled: (ed, a) {
      final o = _chart3D(ed, a);
      return o != null && ChartSpec.fromJson(o.specJson).is3D;
    },
    run: (ctx, ed, a) {
      final o = _chart3D(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final spec = ChartSpec.fromJson(o.specJson);
      _writeSpec(
        ctx,
        ed,
        o,
        spec.copyWith(
          threeD: spec.threeD.copyWith(
            clearAzimuth: true,
            clearElevation: true,
          ),
        ),
      );
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.chart.rotate3D',
    label: (l) => l.cmdChartRotate3D,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    // Alt+Shift+arrows orbit a selected 3D chart by 5° (08 §23.6).
    argBindings: [
      for (final (key, da, de) in const [
        ('ArrowLeft', -5, 0),
        ('ArrowRight', 5, 0),
        ('ArrowUp', 0, 5),
        ('ArrowDown', 0, -5),
      ])
        ArgsKeyBinding(KeyBinding(key, alt: true, shift: true), {
          'dAzimuth': da,
          'dElevation': de,
        }, scope: objectKeyScope),
    ],
    undoLabelOf: (l, a) => l.undoEditChart,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': _idProp,
        'azimuth': JsonSchema.number(description: 'Rotation in degrees.'),
        'elevation': JsonSchema.number(description: 'Tilt, 0–90 degrees.'),
        'dAzimuth': JsonSchema.number(description: 'Turn by degrees.'),
        'dElevation': JsonSchema.number(description: 'Tilt by degrees.'),
      },
    ),
    enabled: (ed, a) {
      final o = _chart3D(ed, a);
      return o != null && ChartSpec.fromJson(o.specJson).is3D;
    },
    run: (ctx, ed, a) {
      final o = _chart3D(ed, a);
      if (o == null) return CommandResult.failed(_missing(ed));
      final spec = ChartSpec.fromJson(o.specJson);
      final t = spec.threeD;
      final az =
          (a.values['azimuth'] as num?)?.toDouble() ??
          t.azimuthFor(spec.type) +
              ((a.values['dAzimuth'] as num?)?.toDouble() ?? 0);
      final el =
          ((a.values['elevation'] as num?)?.toDouble() ??
                  t.elevationFor(spec.type) +
                      ((a.values['dElevation'] as num?)?.toDouble() ?? 0))
              .clamp(ChartThreeD.minElevation, ChartThreeD.maxElevation);
      _writeSpec(
        ctx,
        ed,
        o,
        spec.copyWith(
          threeD: t.copyWith(
            azimuth: ChartThreeD.normalizeAzimuth(az),
            elevation: el,
          ),
        ),
        coalesceKey: 'rotate3D',
      );
      return ok({'objectId': o.id, 'azimuth': az, 'elevation': el});
    },
  ),
];
