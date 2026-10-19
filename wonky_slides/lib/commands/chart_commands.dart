import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart' show ValueKey;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_charts/wonky_charts.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart'
    show ChartDataTableStrings, chartDataJson, chartSceneToPng;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/charts.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/motion.dart' show BuildOptions;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show ElementCols, SlidesCols;
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoEntry;
import 'package:wonky_slides_core/themes.dart' show SuRect;
import 'package:wonky_revlog/rows.dart';

import '../config/panels/slides_panels.dart';
import '../config/slides_features.dart';
import '../features/canvas/canvas_interactions.dart';
import '../features/canvas/slide_canvas_controller.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/elements/chart/chart_api.dart';
import '../features/elements/chart/chart_canvas_mode.dart';
import '../features/elements/chart/chart_elements.dart';
import '../features/elements/chart/chart_insert_dialog.dart';
import '../features/elements/chart/chart_links.dart';
import '../features/elements/chart/chart_text.dart';
import '../features/elements/element_activation.dart';
import 'package:wonky_app/platform.dart' show ImageClipboard;
import '../features/settings/slides_user_defaults.dart';
import '../l10n/slides_l10n.dart';
import '../mcp/dialog_adapters.dart' show showDescribableChartDataDialog;
import 'canvas_commands.dart' show mergeRowChanges;
import 'slides_command.dart';

/// The chart element commands of SL-32 (Slides 08 §4–§10, §14): insert from
/// Wonky Sheets (dialog or ids), *Update* / *Update all*, *Update
/// automatically*, unlink, relink, *Open source spreadsheet*, restyle (deck
/// theme or source look), style overrides within the allowlist, reset, the
/// 3D camera (presets, angles, `Alt+Shift+arrows`), camera build steps,
/// *View data as table*, *Check for updates*, *Copy chart as image* and the
/// Linked charts panel. Every mutating command is one `slides.rows` undo
/// step; camera and style edits with a coalesce key merge within the undo
/// window (drags, sliders, keys).
List<Command<CommandArgs>> chartCommands(ShellServices s) {
  CanvasInteractions.register(ChartCanvasMode.new);
  ElementActivations.register(_chartActivation);
  return [
    SlidesCommand(
      'slides.insert.chartFromSheets',
      label: (l) => l.cmdInsertChartFromSheets,
      icon: LucideIcons.sheet,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      undoLabelOf: (l, a) => l.undoInsertChart,
      descriptionText: (l) => l.cmdInsertChartFromSheetsDescription,
      argsSchema: const JsonSchema.object(
        properties: {
          'spreadsheetUuid': JsonSchema.string(
            description: 'Drive item uuid of the spreadsheet.',
          ),
          'chartObjectIds': JsonSchema.array(
            JsonSchema.string(),
            description: 'Chart ids (MCP chart_id). Without: the dialog.',
          ),
          'link': JsonSchema.boolean(
            description: 'Link to the spreadsheet (default true).',
          ),
          'useDeckTheme': JsonSchema.boolean(
            description: 'Match the presentation theme (default true).',
          ),
          ..._frameProps,
        },
      ),
      enabled: (ed, a) => ed.surfaceId != null && _online(ed),
      reason: (l, ed) =>
          ed.surfaceId == null ? l.reasonNoSlides : l.chartErrOffline,
      run: (ctx, ed, a) async {
        final l = slidesL10nOf(ed.services);
        var uuid = a.string('spreadsheetUuid');
        var ids = a.strings('chartObjectIds');
        var link = a.boolean('link') ?? true;
        var deck = a.boolean('useDeckTheme') ?? true;
        if (uuid == null || ids.isEmpty) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed(
              'spreadsheetUuid and chartObjectIds are required',
            );
          }
          final c = await showChartInsertDialog(
            dc,
            services: ed.services,
            editor: ed,
            spreadsheetUuid: uuid,
          );
          if (c == null) return const CommandResult.cancelled();
          uuid = c.spreadsheetUuid;
          ids = c.chartObjectIds;
          link = c.link;
          deck = c.useDeckTheme;
        }
        final snaps = <ResolvedChartSnapshot>[];
        for (final id in ids) {
          try {
            snaps.add(await SlidesChartApi.of(ed.services).resolve(uuid, id));
          } on ChartApiException catch (e) {
            return _apiFailure(ctx, ed, l, e);
          }
        }
        return _insertResolved(
          ctx,
          ed,
          snaps,
          link: link,
          useDeckTheme: deck,
          frame: _frameArg(a),
        );
      },
    ),
    SlidesCommand(
      'slides.chart.insertLinked',
      label: (l) => l.cmdInsertChartFromSheets,
      icon: LucideIcons.sheet,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      showInPalette: false,
      undoLabelOf: (l, a) => l.undoInsertChart,
      argsSchema: const JsonSchema.object(
        properties: {
          'snapshots': JsonSchema.array(
            JsonSchema.object(
              properties: {
                'spreadsheetUuid': JsonSchema.string(),
                'chartObjectId': JsonSchema.string(),
                'sourceSpecJson': JsonSchema.string(),
                'dataSnapshotJson': JsonSchema.string(),
                'sourceVersion': JsonSchema.string(),
                'sheetId': JsonSchema.string(),
              },
              required: [
                'spreadsheetUuid',
                'chartObjectId',
                'sourceSpecJson',
                'dataSnapshotJson',
                'sourceVersion',
              ],
            ),
          ),
          'link': JsonSchema.boolean(),
          'useDeckTheme': JsonSchema.boolean(),
          ..._frameProps,
        },
        required: ['snapshots'],
      ),
      enabled: (ed, a) => ed.surfaceId != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        final raw = a.values['snapshots'];
        final snaps = <ResolvedChartSnapshot>[
          for (final m in raw is List ? raw : const [])
            if (m is Map)
              ResolvedChartSnapshot(
                spreadsheetUuid: '${m['spreadsheetUuid']}',
                chartObjectId: '${m['chartObjectId']}',
                sourceSpecJson: '${m['sourceSpecJson']}',
                dataSnapshotJson: '${m['dataSnapshotJson']}',
                sourceVersion: '${m['sourceVersion']}',
                sheetId: m['sheetId'] as String?,
              ),
        ];
        if (snaps.isEmpty) return const CommandResult.failed('No snapshots');
        return _insertResolved(
          ctx,
          ed,
          snaps,
          link: a.boolean('link') ?? true,
          useDeckTheme: a.boolean('useDeckTheme') ?? true,
          frame: _frameArg(a),
        );
      },
    ),
    SlidesCommand(
      'slides.chart.update',
      label: (l) => l.cmdChartUpdate,
      dynamicLabel: (l, ed) => ed.selectedElementIds.length > 1
          ? l.cmdChartUpdateMany
          : l.cmdChartUpdate,
      icon: LucideIcons.refreshCw,
      categoryOf: SlidesCategory.format,
      mutates: true,
      undoLabelOf: (l, a) => l.undoUpdateChart,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementIds': _idsSchema,
          'elementId': JsonSchema.string(),
          'all': JsonSchema.boolean(
            description: 'Every linked chart whose source changed.',
          ),
        },
      ),
      enabled: (ed, a) => _online(ed) && _updateTargets(ed, a).isNotEmpty,
      reason: (l, ed) =>
          !_online(ed) ? l.chartErrOffline : l.reasonSelectLinkedChart,
      run: (ctx, ed, a) async {
        final l = slidesL10nOf(ed.services);
        final targets = _updateTargets(ed, a);
        final links = ChartLinks.of(ed);
        final api = SlidesChartApi.of(ed.services);
        final done = <String>[];
        for (final e in targets) {
          final link = ed.model.chartLinkOf(e.id);
          if (link == null) continue;
          try {
            final r = await api.resolve(
              link.spreadsheetItemUuid,
              link.chartObjectId,
            );
            ChartCanvasMode.of(ed)?.morphFrom(e.id);
            ed.apply(ctx, ChartLinkOps.update(e.id, r));
            _refreshAltText(ctx, ed, e.id);
            links.markUpToDate(e.id, r.sourceVersion);
            done.add(e.id);
          } on ChartApiException catch (err) {
            links.markFailed(e.id, err.error);
            if (targets.length == 1) return _apiFailure(ctx, ed, l, err);
          }
        }
        if (done.isEmpty) return CommandResult.failed(l.chartErrFailed);
        return ok({'elementIds': done});
      },
    ),
    SlidesCommand(
      'slides.chart.setAutoUpdate',
      label: (l) => l.cmdChartSetAutoUpdate,
      icon: LucideIcons.refreshCcwDot,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementIds': _idsSchema,
          'elementId': JsonSchema.string(),
          'autoUpdate': JsonSchema.boolean(
            description: 'On or off (default: toggle).',
          ),
        },
      ),
      enabled: (ed, a) => _linkedTargets(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectLinkedChart,
      checked: (ed, a) {
        final els = _linkedTargets(ed, a);
        if (els.isEmpty) return false;
        return els.every((e) => ed.model.chartLinkOf(e.id)?.autoUpdate == true);
      },
      run: (ctx, ed, a) {
        final els = _linkedTargets(ed, a);
        final on =
            a.boolean('autoUpdate') ??
            !els.every((e) => ed.model.chartLinkOf(e.id)?.autoUpdate == true);
        for (final e in els) {
          if (ed.model.chartLinkOf(e.id)?.autoUpdate == on) continue;
          ed.apply(ctx, SetChartAutoUpdate(e.id, on));
        }
        // Turning it on applies a pending update at the next check.
        if (on) unawaited(ChartLinks.of(ed).check());
        return ok({'autoUpdate': on});
      },
    ),
    SlidesCommand(
      'slides.chart.unlink',
      label: (l) => l.cmdChartUnlink,
      icon: LucideIcons.unlink,
      categoryOf: SlidesCategory.format,
      mutates: true,
      undoLabelOf: (l, a) => l.undoUnlinkChart,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementIds': _idsSchema,
          'elementId': JsonSchema.string(),
        },
      ),
      enabled: (ed, a) => _linkedTargets(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectLinkedChart,
      run: (ctx, ed, a) {
        final els = _linkedTargets(ed, a);
        for (final e in els) {
          ed.apply(ctx, UnlinkChart(e.id));
        }
        return ok({
          'elementIds': [for (final e in els) e.id],
        });
      },
    ),
    SlidesCommand(
      'slides.chart.relink',
      label: (l) => l.cmdChartRelink,
      icon: LucideIcons.link,
      categoryOf: SlidesCategory.format,
      mutates: true,
      undoLabelOf: (l, a) => l.undoRelinkChart,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementId': JsonSchema.string(),
          'spreadsheetUuid': JsonSchema.string(),
          'chartObjectId': JsonSchema.string(
            description: 'Without: the dialog (at the current spreadsheet).',
          ),
        },
      ),
      enabled: (ed, a) => _online(ed) && _single(ed, a) != null,
      reason: (l, ed) => !_online(ed) ? l.chartErrOffline : l.reasonSelectChart,
      run: (ctx, ed, a) async {
        final l = slidesL10nOf(ed.services);
        final e = _single(ed, a)!;
        final current = ed.model.chartLinkOf(e.id);
        var uuid = a.string('spreadsheetUuid') ?? current?.spreadsheetItemUuid;
        var chart = a.string('chartObjectId');
        if (chart == null || uuid == null) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed(
              'spreadsheetUuid and chartObjectId are required',
            );
          }
          final c = await showChartInsertDialog(
            dc,
            services: ed.services,
            editor: ed,
            spreadsheetUuid: uuid,
            single: true,
            useDeckTheme: ChartElements.dataOf(e).style.useDeckTheme,
          );
          if (c == null) return const CommandResult.cancelled();
          uuid = c.spreadsheetUuid;
          chart = c.chartObjectIds.single;
        }
        try {
          final r = await SlidesChartApi.of(ed.services).resolve(uuid, chart);
          ChartCanvasMode.of(ed)?.morphFrom(e.id);
          ed.apply(
            ctx,
            ChartLinkOps.link(
              e.id,
              r,
              autoUpdate: current?.autoUpdate ?? _autoDefault(ed),
            ),
          );
          _refreshAltText(ctx, ed, e.id);
          ChartLinks.of(ed).markUpToDate(e.id, r.sourceVersion);
          return ok({'elementId': e.id});
        } on ChartApiException catch (err) {
          return _apiFailure(ctx, ed, l, err);
        }
      },
    ),
    SlidesCommand(
      'slides.chart.openSource',
      label: (l) => l.cmdChartOpenSource,
      icon: LucideIcons.sheet,
      categoryOf: SlidesCategory.format,
      argsSchema: const JsonSchema.object(
        properties: {'elementId': JsonSchema.string()},
      ),
      enabled: (ed, a) => _online(ed) && _linkedSingle(ed, a) != null,
      reason: (l, ed) =>
          !_online(ed) ? l.chartErrOffline : l.reasonSelectLinkedChart,
      run: (ctx, ed, a) async {
        final e = _linkedSingle(ed, a)!;
        final link = ed.model.chartLinkOf(e.id)!;
        final path =
            '/s/${link.spreadsheetItemUuid}'
            '?object=${Uri.encodeQueryComponent(link.chartObjectId)}';
        if (!ctx.source.isAgent) {
          await ed.services.crossApp.open(WonkyAppKind.sheets, path);
        }
        return ok({'path': '/sheets$path'});
      },
    ),
    SlidesCommand(
      'slides.chart.setUseDeckTheme',
      label: (l) => l.cmdChartSetUseDeckTheme,
      icon: LucideIcons.paintbrush,
      categoryOf: SlidesCategory.format,
      mutates: true,
      undoLabelOf: (l, a) => l.undoEditChartStyle,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementIds': _idsSchema,
          'elementId': JsonSchema.string(),
          'useDeckTheme': JsonSchema.boolean(
            description: 'true: Match theme; false: Keep source style.',
          ),
        },
        required: ['useDeckTheme'],
      ),
      enabled: (ed, a) => _targets(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectChart,
      checked: (ed, a) {
        final v = a.boolean('useDeckTheme');
        final els = _targets(ed, a);
        if (v == null || els.isEmpty) return null;
        return els.every(
          (e) => ChartElements.dataOf(e).style.useDeckTheme == v,
        );
      },
      run: (ctx, ed, a) {
        final v = a.values['useDeckTheme'] == true;
        for (final e in _targets(ed, a)) {
          if (ChartElements.dataOf(e).style.useDeckTheme == v) continue;
          ed.apply(
            ctx,
            SetChartStyle(e.id, {
              'style': {'useDeckTheme': v},
            }),
          );
        }
        return ok({'useDeckTheme': v});
      },
    ),
    SlidesCommand(
      'slides.chart.updateStyle',
      label: (l) => l.cmdChartUpdateStyle,
      icon: LucideIcons.slidersHorizontal,
      categoryOf: SlidesCategory.format,
      mutates: true,
      showInPalette: false,
      undoLabelOf: (l, a) => l.undoEditChartStyle,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementIds': _idsSchema,
          'elementId': JsonSchema.string(),
          'patch': JsonSchema.object(
            additionalProperties: true,
            description:
                'RFC 7386 merge patch of the style overrides over the source '
                'spec (08 §8.2 allowlist: title, subtitle, legend, '
                'axes.*.title/labels/showLine/numberFormat, gridlines, '
                'series.<key>.color/lineWidth/pointSize/pointShape/'
                'dataLabels/labelOverride, style.background/fontFamily/'
                'border/maximize/palette, threeD.lighting/wallsVisible/'
                'floorColor/depth/gapDepth/shape/explode, typeOptions.pieHole/'
                'sliceLabel/startAngle/slices).',
          ),
          'options': JsonSchema.object(
            additionalProperties: true,
            description:
                'Deck-side keys: background (transparent | theme | #hex | '
                'null), interactive {hoverTooltips, orbitInPresent}, style '
                '{palette, font}.',
          ),
          'coalesceKey': JsonSchema.string(),
        },
      ),
      enabled: (ed, a) => _targets(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectChart,
      run: (ctx, ed, a) {
        final patch = _obj(a.values['patch']);
        final options = _obj(a.values['options']);
        if (patch == null && options == null) {
          return const CommandResult.failed('patch or options is required');
        }
        if (patch != null) {
          final rejected = ChartOverrides.rejectedPaths(patch);
          if (rejected.isNotEmpty) {
            return CommandResult.failed(
              'invalid_args: ${rejected.join(', ')} can only be edited in '
              'Wonky Sheets',
              {'paths': rejected},
            );
          }
        }
        if (options != null) {
          final bad = [
            for (final k in options.keys)
              if (!const {'background', 'interactive', 'style'}.contains(k)) k,
          ];
          final style = _obj(options['style']);
          if (style != null && style.containsKey('useDeckTheme')) {
            bad.add('style.useDeckTheme');
          }
          if (bad.isNotEmpty) {
            return CommandResult.failed('invalid_args: ${bad.join(', ')}', {
              'paths': bad,
            });
          }
        }
        final ops = <SlidesOperation>[
          for (final e in _targets(ed, a))
            SetChartStyle(e.id, {...?options, 'overrides': ?patch}),
        ];
        _applyMaybeCoalesced(ctx, ed, ops, a.string('coalesceKey'));
        return ok();
      },
    ),
    SlidesCommand(
      'slides.chart.resetOverrides',
      label: (l) => l.cmdChartResetOverrides,
      icon: LucideIcons.rotateCcw,
      categoryOf: SlidesCategory.format,
      mutates: true,
      undoLabelOf: (l, a) => l.undoEditChartStyle,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementIds': _idsSchema,
          'elementId': JsonSchema.string(),
          'series': JsonSchema.array(
            JsonSchema.string(),
            description: 'Only these series keys (Clean up unused).',
          ),
        },
      ),
      enabled: (ed, a) => _targets(
        ed,
        a,
      ).any((e) => ChartElements.dataOf(e).overrides.isNotEmpty),
      reason: (l, ed) => l.reasonChartNoOverrides,
      run: (ctx, ed, a) {
        final series = a.strings('series');
        for (final e in _targets(ed, a)) {
          if (ChartElements.dataOf(e).overrides.isEmpty) continue;
          ed.apply(
            ctx,
            SetChartStyle(e.id, {
              'overrides': series.isEmpty
                  ? null
                  : {
                      'series': {for (final k in series) k: null},
                    },
            }),
          );
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.chart.setCamera',
      label: (l) => l.cmdChartSetCamera,
      icon: LucideIcons.rotate3d,
      categoryOf: SlidesCategory.format,
      mutates: true,
      keyScope: SlidesKeyScopes.canvas,
      undoLabelOf: (l, a) => l.undoRotateChart,
      argBindings: const [
        ArgsKeyBinding(KeyBinding('ArrowLeft', alt: true, shift: true), {
          'deltaAzimuth': -5,
        }),
        ArgsKeyBinding(KeyBinding('ArrowRight', alt: true, shift: true), {
          'deltaAzimuth': 5,
        }),
        ArgsKeyBinding(KeyBinding('ArrowUp', alt: true, shift: true), {
          'deltaElevation': 5,
        }),
        ArgsKeyBinding(KeyBinding('ArrowDown', alt: true, shift: true), {
          'deltaElevation': -5,
        }),
      ],
      argsSchema: JsonSchema.object(
        properties: {
          'elementId': const JsonSchema.string(),
          'azimuth': const JsonSchema.number(description: 'Degrees.'),
          'elevation': const JsonSchema.number(minimum: 0, maximum: 90),
          'perspective': const JsonSchema.number(minimum: 0, maximum: 60),
          'deltaAzimuth': const JsonSchema.number(),
          'deltaElevation': const JsonSchema.number(),
          'preset': JsonSchema.string(
            enumValues: [
              ...Chart3DView.presets.keys,
              ...Chart3DView.piePresets.keys.where(
                (k) => !Chart3DView.presets.containsKey(k),
              ),
            ],
          ),
          'reset': const JsonSchema.boolean(
            description: "Back to the source spec's view.",
          ),
        },
      ),
      enabled: (ed, a) => _camera3D(ed, a) != null,
      reason: (l, ed) => l.reasonSelect3DChart,
      run: (ctx, ed, a) {
        final e = _camera3D(ed, a)!;
        final snap = ChartElements.snapshotOf(ed, e.id)!;
        final current = ChartElements.cameraOf(ed, e.id)!;
        Chart3DView? next;
        if (a.boolean('reset') == true) {
          next = null;
        } else {
          final preset = a.string('preset');
          if (preset != null) {
            next = Chart3DView.preset(preset, type: snap.spec.type);
            if (next == null) {
              return CommandResult.failed('Unknown preset $preset');
            }
          } else {
            double? n(String k) => (a.values[k] as num?)?.toDouble();
            next = Chart3DView(
              azimuth:
                  (n('azimuth') ?? current.azimuth) + (n('deltaAzimuth') ?? 0),
              elevation:
                  (n('elevation') ?? current.elevation) +
                  (n('deltaElevation') ?? 0),
              perspective: n('perspective') ?? current.perspective,
            ).normalized;
          }
        }
        final v = next == null
            ? null
            : Chart3DView(
                azimuth: (next.normalizedAzimuth * 10).round() / 10,
                elevation: (next.elevation * 10).round() / 10,
                perspective: (next.perspective * 10).round() / 10,
              );
        _applyMaybeCoalesced(ctx, ed, [
          SetChartStyle(e.id, {'camera': v?.toJson()}),
        ], 'slides.chart.camera:${e.id}');
        return ok({'camera': v?.toJson()});
      },
    ),
    if (SlidesFeatures.isOn(SlidesFeature.animations))
      SlidesCommand(
        'slides.chart.addCameraStep',
        label: (l) => l.cmdChartAddCameraStep,
        icon: LucideIcons.rotate3d,
        categoryOf: SlidesCategory.animations,
        mutates: true,
        argsSchema: const JsonSchema.object(
          properties: {
            'elementId': JsonSchema.string(),
            'preset': JsonSchema.string(),
            'azimuth': JsonSchema.number(),
            'elevation': JsonSchema.number(),
            'perspective': JsonSchema.number(),
            'durationMs': JsonSchema.integer(minimum: 0),
          },
        ),
        enabled: (ed, a) =>
            _camera3D(ed, a) != null &&
            ed.model.slide(ed.surfaceId ?? '') != null,
        reason: (l, ed) => l.reasonSelect3DChart,
        run: (ctx, ed, a) {
          final e = _camera3D(ed, a)!;
          final cam = ChartElements.cameraOf(ed, e.id)!;
          final preset = a.string('preset');
          final params = preset != null
              ? {'preset': preset}
              : {
                  'azimuth':
                      (a.values['azimuth'] as num?) ?? cam.normalizedAzimuth,
                  'elevation': (a.values['elevation'] as num?) ?? cam.elevation,
                  'perspective':
                      (a.values['perspective'] as num?) ?? cam.perspective,
                };
          final plan = ed.apply(
            ctx,
            AddBuilds(ed.surfaceId!, [
              BuildSpec(
                elementId: e.id,
                kind: SlideBuildKind.emphasis,
                effect: 'chartCamera',
                durationMs: a.integer('durationMs') ?? 1200,
                easing: 'easeInOutCubic',
                optionsJson: jsonEncode(BuildOptions(params: params).toJson()),
              ),
            ]),
          );
          return ok(plan.result);
        },
      ),
    SlidesCommand(
      'slides.chart.viewDataTable',
      label: (l) => l.cmdChartViewDataTable,
      icon: LucideIcons.table,
      categoryOf: SlidesCategory.format,
      argsSchema: const JsonSchema.object(
        properties: {'elementId': JsonSchema.string()},
      ),
      enabled: (ed, a) =>
          _anySingle(ed, a) != null &&
          ChartElements.snapshotOf(ed, _anySingle(ed, a)!.id) != null,
      reason: (l, ed) => l.reasonSelectChart,
      run: (ctx, ed, a) async {
        final e = _anySingle(ed, a)!;
        final snap = ChartElements.snapshotOf(ed, e.id)!;
        final locale = snap.dataSnapshot.locale;
        final dc = ctx.dialogContext;
        if (dc == null || ctx.source.isAgent) {
          return ok(chartDataJson(snap.data, locale: locale));
        }
        final l = slidesL10nOf(ed.services);
        final title = snap.spec.title.hasText
            ? snap.spec.title.text
            : snap.dataSnapshot.source.chartTitle;
        await showDescribableChartDataDialog(
          dc,
          data: snap.data,
          locale: locale,
          dialogKey: const ValueKey<String>('dialog.slides.chartData'),
          strings: ChartDataTableStrings(
            title: l.chartDataTableTitle(
              title.isEmpty ? l.chartUntitled : title,
            ),
            close: WonkyAppLocalizations.of(dc).actionClose,
            noData: l.chartNoData,
          ),
        );
        return ok();
      },
    ),
    SlidesCommand(
      'slides.chart.checkUpdates',
      label: (l) => l.cmdChartCheckUpdates,
      icon: LucideIcons.refreshCw,
      categoryOf: SlidesCategory.tools,
      enabled: (ed, a) => _online(ed),
      reason: (l, ed) => l.chartErrOffline,
      run: (ctx, ed, a) async {
        final links = ChartLinks.of(ed);
        await links.check();
        return ok({
          'charts': [
            for (final p in ChartLinkOps.probesOf(ed.model))
              {
                'elementId': p.elementId,
                'status': links.statusOf(p.elementId)?.name,
              },
          ],
        });
      },
    ),
    SlidesCommand(
      'slides.panel.linkedObjects',
      label: (l) => l.cmdPanelLinkedObjects,
      icon: LucideIcons.link2,
      categoryOf: SlidesCategory.view,
      checked: (ed, a) => s.panels.isOpen(SlidesPanels.linkedObjects),
      run: (ctx, ed, a) {
        s.panels.toggle(SlidesPanels.linkedObjects);
        if (s.panels.isOpen(SlidesPanels.linkedObjects)) {
          unawaited(ChartLinks.of(ed).check());
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.chart.copyAsImage',
      label: (l) => l.cmdChartCopyAsImage,
      icon: LucideIcons.imageDown,
      categoryOf: SlidesCategory.format,
      argsSchema: const JsonSchema.object(
        properties: {'elementId': JsonSchema.string()},
      ),
      enabled: (ed, a) =>
          ImageClipboard.instance.supported &&
          _anySingle(ed, a) != null &&
          ChartElements.snapshotOf(ed, _anySingle(ed, a)!.id) != null,
      reason: (l, ed) => l.reasonSelectChart,
      run: (ctx, ed, a) async {
        final e = _anySingle(ed, a)!;
        final b = ChartElements.buildOf(ed, e.id);
        if (b == null) return const CommandResult.failed('No chart data');
        // Charts with a transparent background get the slide color behind.
        var scene = b.scene;
        if (scene.background >>> 24 == 0) {
          scene = ChartScene(
            width: scene.width,
            height: scene.height,
            background: b.look.theme.background,
            primitives: scene.primitives,
            plotArea: scene.plotArea,
            threeD: scene.threeD,
          );
        }
        final png = await chartSceneToPng(
          scene,
          pixelRatio: 3,
          text: SlidesChartText.measurer,
        );
        final l = slidesL10nOf(ed.services);
        if (png == null ||
            !await ImageClipboard.instance.writePng(
              png,
              text: ChartDescriber.describe(b.look.spec, b.snapshot.data),
            )) {
          return CommandResult.failed(l.chartCopyFailed);
        }
        if (!ctx.source.isAgent) ed.services.toasts.show(l.chartCopied);
        return ok({'bytes': png.length});
      },
    ),
  ];
}

// ----------------------------------------------------------------- helpers

const _idsSchema = JsonSchema.array(JsonSchema.string());

const _frameProps = <String, JsonSchema>{
  'x': JsonSchema.number(),
  'y': JsonSchema.number(),
  'width': JsonSchema.number(),
  'height': JsonSchema.number(),
};

bool _online(DeckEditorController ed) => SlidesChartApi.of(ed.services).online;

bool _autoDefault(DeckEditorController ed) =>
    ed.defaults.flag(SlidesUserDefaults.keyChartsAutoUpdate);

Map<String, Object?>? _obj(Object? v) =>
    v is Map ? v.map((k, v) => MapEntry('$k', v)) : null;

SuRect? _frameArg(JsonArgs a) {
  num? n(String k) => a.values[k] is num ? a.values[k] as num : null;
  final x = n('x'), y = n('y'), w = n('width'), h = n('height');
  if (x == null || y == null || w == null || h == null) return null;
  return SuRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
}

/// The chart elements named by `elementIds`/`elementId`, or the selected
/// ones (unlocked).
List<SlideElementRec> _targets(DeckEditorController ed, JsonArgs a) {
  final ids = a.strings('elementIds');
  final one = a.string('elementId');
  final source = ids.isNotEmpty
      ? ids
      : one != null
      ? [one]
      : ed.selectedElementIds;
  return [
    for (final id in source)
      if (ed.model.element(id) case final e?)
        if (ChartElements.isChart(e) && !e.locked) e,
  ];
}

List<SlideElementRec> _linkedTargets(DeckEditorController ed, JsonArgs a) => [
  for (final e in _targets(ed, a))
    if (ChartElements.isLinked(ed, e)) e,
];

/// `all: true` = every changed link of the deck; else the linked targets.
List<SlideElementRec> _updateTargets(DeckEditorController ed, JsonArgs a) {
  if (a.boolean('all') == true) {
    return [
      for (final id in ChartLinks.maybeOf(ed)?.changedIds ?? const <String>[])
        if (ed.model.element(id) case final e? when !e.locked) e,
    ];
  }
  return _linkedTargets(ed, a);
}

/// The single chart of `elementId` or the selection (locked ones too —
/// read-only commands).
SlideElementRec? _anySingle(DeckEditorController ed, JsonArgs a) {
  final id =
      a.string('elementId') ??
      (ed.selectedElementIds.length == 1 ? ed.selectedElementIds.single : null);
  final e = id == null ? null : ed.model.element(id);
  return ChartElements.isChart(e) ? e : null;
}

SlideElementRec? _single(DeckEditorController ed, JsonArgs a) {
  final e = _anySingle(ed, a);
  return e == null || e.locked ? null : e;
}

SlideElementRec? _linkedSingle(DeckEditorController ed, JsonArgs a) {
  final e = _anySingle(ed, a);
  return e != null && ChartElements.isLinked(ed, e) ? e : null;
}

SlideElementRec? _camera3D(DeckEditorController ed, JsonArgs a) {
  final e = _single(ed, a);
  return e != null && ChartElements.is3D(ed, e.id) ? e : null;
}

CommandResult _apiFailure(
  CommandContext ctx,
  DeckEditorController ed,
  SlidesLocalizations l,
  ChartApiException e,
) {
  if (e.error == ChartApiError.quotaExceeded && !ctx.source.isAgent) {
    ed.services.quotaErrors.present(
      ChartApiException(e.error, e.message),
      reason: QuotaReasons.image,
    );
  }
  return CommandResult.failed(chartErrorMessage(l, e.error), {
    'reason': e.error.name,
  });
}

/// Applies [ops]; with [coalesceKey] as one step merged into the previous
/// step of the same key within the undo window (drags, sliders, keys).
void _applyMaybeCoalesced(
  CommandContext ctx,
  DeckEditorController ed,
  List<SlidesOperation> ops,
  String? coalesceKey,
) {
  final doc = ctx.document;
  if (coalesceKey == null || doc == null || ctx.transaction == null) {
    for (final op in ops) {
      ed.apply(ctx, op);
    }
    return;
  }
  final changes = <RowChange>[];
  String? label;
  for (final op in ops) {
    final plan = ed.session.execute(op);
    changes.addAll(plan.changes);
    label ??= plan.label;
  }
  if (changes.isEmpty) return;
  final undo = ed.services.undo;
  final stack = doc.undoStackKey;
  final steps = undo.undoStepsOf(stack);
  final top = steps.isEmpty ? null : steps.last;
  final now = clock.now();
  final l = slidesL10nOf(ed.services);
  final stepLabel = coalesceKey.startsWith('slides.chart.camera')
      ? l.undoRotateChart
      : l.undoEditChartStyle;
  if (top != null &&
      top.coalesceKey == coalesceKey &&
      now.difference(top.updatedAt) <= undo.coalesceWindow &&
      top.entries.length == 1 &&
      top.entries.single is SlidesRowsUndoEntry) {
    final prev = top.entries.single as SlidesRowsUndoEntry;
    undo.replaceLast(
      UndoStep(
        id: top.id,
        label: top.label,
        entries: [
          SlidesRowsUndoEntry(
            mergeRowChanges(prev.changes, changes),
            label: prev.label,
          ),
        ],
        selectionBefore: top.selectionBefore,
        selectionAfter: ctx.selection,
        createdAt: top.createdAt,
        updatedAt: now,
        source: top.source,
        coalesceKey: coalesceKey,
      ),
      stack: stack,
    );
    return;
  }
  undo.push(
    UndoStep(
      id: ed.services.ids.nextString(),
      label: stepLabel,
      entries: [SlidesRowsUndoEntry(changes, label: label ?? stepLabel)],
      selectionBefore: ctx.selection,
      selectionAfter: ctx.selection,
      source: ctx.source,
      coalesceKey: coalesceKey,
    ),
    stack: stack,
  );
}

/// The alt text of a chart follows its data unless the author edited it
/// (08 §17): an empty or generated description is regenerated.
void _refreshAltText(CommandContext ctx, DeckEditorController ed, String id) {
  final e = ed.model.element(id);
  final snap = ChartElements.snapshotOf(ed, id);
  if (e == null || snap == null) return;
  final next = ChartDescriber.describe(snap.spec, snap.data);
  final cur = e.altText;
  if (cur == next) return;
  if (cur != null && cur.isNotEmpty && !_generated(cur)) return;
  ed.apply(ctx, SetElementProps([id], altText: Patch(next)));
}

/// Whether [alt] looks like a `ChartDescriber` description.
bool _generated(String alt) =>
    RegExp(r'^(\S+ )?(chart|Chart|Scorecard|Table)\b.*:').hasMatch(alt);

/// Inserts the resolved charts (one undo step "Insert chart", 08 §4.2):
/// into the selected empty chart placeholder (filled in place), else new
/// elements in [frame] or centered at 70 % of the slide width (a grid when
/// several).
CommandResult _insertResolved(
  CommandContext ctx,
  DeckEditorController ed,
  List<ResolvedChartSnapshot> snaps, {
  required bool link,
  required bool useDeckTheme,
  SuRect? frame,
}) {
  final slideId = ed.surfaceId;
  if (slideId == null) return const CommandResult.failed('No slide');
  final auto = _autoDefault(ed);
  final created = <String>[];
  var rest = snaps;
  // An empty chart placeholder takes the first chart.
  final sel = ed.selectedElementIds;
  if (sel.length == 1 && frame == null) {
    final r = ed.resolver.resolve(slideId);
    final target = r?.elements.where((x) => x.id == sel.single).firstOrNull;
    if (target != null && ChartElements.isEmptyPlaceholder(ed, target)) {
      final s = rest.first;
      ed.apply(ctx, ChartLinkOps.link(target.id, s, autoUpdate: auto));
      ed.apply(
        ctx,
        SetChartStyle(target.id, {
          'style': {'useDeckTheme': useDeckTheme},
        }),
      );
      if (!link) ed.apply(ctx, UnlinkChart(target.id));
      _refreshAltText(ctx, ed, target.id);
      created.add(target.id);
      rest = rest.sublist(1);
    }
  }
  if (rest.isNotEmpty) {
    final d = ed.model.deck;
    final frames = ChartElements.placements(
      rest.length,
      slideWidth: d?.width ?? 1920,
      slideHeight: d?.height ?? 1080,
      area: frame,
    );
    final specs = <ElementSpec>[];
    for (final (i, r) in rest.indexed) {
      final snap = ChartSourceSnapshot.fromColumns(
        r.sourceSpecJson,
        r.dataSnapshotJson,
      );
      final data = ChartElementData(
        source: link ? SlideChartSource.linked : SlideChartSource.static,
        style: SlideChartStyle(useDeckTheme: useDeckTheme),
        snapshot: link ? null : snap,
      );
      final title = snap.spec.title.hasText
          ? snap.spec.title.text
          : snap.dataSnapshot.source.chartTitle;
      final f = frames[i];
      specs.add(
        ElementSpec(
          kind: ElementKind.chart,
          x: f.x,
          y: f.y,
          width: f.width,
          height: f.height,
          columns: {
            ElementCols.dataJson: data.encode(),
            if (title.isNotEmpty) SlidesCols.name: title,
            ElementCols.altText: ChartDescriber.describe(snap.spec, snap.data),
          },
        ),
      );
    }
    final plan = ed.apply(
      ctx,
      InsertElements(ownerKind: ed.surfaceKind, slideId, specs),
    );
    final ids = [
      for (final x in (plan.result['elementIds'] as List? ?? const [])) '$x',
    ];
    if (link) {
      for (final (i, id) in ids.indexed) {
        ed.apply(ctx, ChartLinkOps.link(id, rest[i], autoUpdate: auto));
      }
    }
    created.addAll(ids);
  }
  final links = ChartLinks.of(ed);
  for (final (i, id) in created.indexed) {
    if (link) links.markUpToDate(id, snaps[i].sourceVersion);
  }
  ed.armTool(null);
  if (created.isNotEmpty) {
    selectionOf(ed).select(created);
    ed.canvasFocus.requestFocus();
  }
  return ok({'elementIds': created, 'linked': link});
}

/// Double-click / Enter on a chart (03 §3.4): an empty chart placeholder
/// opens *Insert chart*, other charts the inspector's Chart section.
final _chartActivation = ElementActivation(
  applies: (ed, a) {
    final ids = ed.selectedElementIds;
    if (ids.length != 1) return false;
    return ChartElements.isChart(ed.model.element(ids.single));
  },
  run: (ctx, ed, a) {
    final e = ed.model.element(ed.selectedElementIds.single)!;
    if (ChartElements.isEmpty(ed, e) && ed.canEdit) {
      return ed.invokeCommand(
        'slides.insert.chartFromSheets',
        const {},
        ctx.source,
        ctx.dialogContext,
      );
    }
    ed.openInspector(InspectorTab.format, section: 'chart');
    return ok({'elementId': e.id});
  },
);
