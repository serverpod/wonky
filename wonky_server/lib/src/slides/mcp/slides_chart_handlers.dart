import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    show ChartDescriber, ChartSourceSnapshot;
import 'package:wonky_slides_core/charts.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../../platform/common/models.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/sharing/access_service.dart';
import '../charts/slides_chart_service.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';
import 'slides_writes.dart';

/// MCP tools for linked Sheets charts in decks (Slides 11 §3, §2.4): list,
/// insert, refresh, restyle and unlink.
abstract final class SlidesChartHandlers {
  /// Linked-chart tools also need `sheets:read` (11 §2.4).
  static void requireSheetsRead(ToolContext ctx) {
    if (!ctx.scopes.contains(McpScope.sheetsRead)) {
      throw McpToolException(
        McpErrorCode.forbidden,
        'Charts from Sheets also need the ${McpScope.sheetsRead} scope.',
        details: {
          'required_scopes': [McpScope.sheetsRead],
        },
      );
    }
  }

  /// Maps `SlidesChartService` errors (08 §4.3 reasons) to tool errors.
  static McpToolException _chartError(WonkyException e) {
    String? reason;
    try {
      final d = e.detailsJson == null ? null : jsonDecode(e.detailsJson!);
      if (d is Map) reason = d['reason'] as String?;
    } on FormatException {
      reason = null;
    }
    final code = switch (reason) {
      'no_access' || 'spreadsheet_trashed' => SlidesErrorCode.chartNoAccess,
      'export_disabled' => SlidesErrorCode.chartExportDisabled,
      'chart_not_found' => SlidesErrorCode.chartNotFound,
      'chart_too_large' => SlidesErrorCode.chartTooLarge,
      'unsupported_spec' => SlidesErrorCode.chartUnsupportedSpec,
      _ => null,
    };
    if (code == null) return McpToolException.fromWonky(e);
    return McpToolException(code, e.message, details: {'reason': reason});
  }

  static Future<ResolvedChartSnapshot> _resolve(
    ToolContext ctx,
    UuidValue spreadsheet,
    String chartId,
  ) async {
    try {
      final v = await SlidesChartService.resolveSnapshot(
        ctx.session,
        ctx.actor,
        spreadsheet,
        chartId,
      );
      return ResolvedChartSnapshot(
        spreadsheetUuid: v.spreadsheetUuid.uuid,
        chartObjectId: v.chartObjectId,
        sourceSpecJson: v.sourceSpecJson,
        dataSnapshotJson: v.dataSnapshotJson,
        sourceVersion: v.sourceVersion,
        sheetId: v.sheetId,
        warnings: v.warnings,
      );
    } on WonkyException catch (e) {
      throw _chartError(e);
    }
  }

  static Future<ToolResult> listSheetCharts(ToolContext ctx, ToolArgs a) async {
    requireSheetsRead(ctx);
    final uuid = SlidesMcp.parseRef(
      a.requireString('spreadsheet'),
      what: 'spreadsheet',
    );
    try {
      final list = await SlidesChartService.listCharts(
        ctx.session,
        ctx.actor,
        uuid,
      );
      return ToolResult({
        'spreadsheet': uuid.uuid,
        'spreadsheet_title': list.spreadsheetTitle,
        'export_allowed': list.exportAllowed,
        'charts': [
          for (final c in list.charts)
            {
              'chart_id': c.chartObjectId,
              'title': c.title,
              'type': c.type,
              'is_3d': c.is3D,
              'sheet': c.sheetName,
              if (c.unsupported) 'unsupported': true,
            },
        ],
      }, text: '${list.charts.length} charts in "${list.spreadsheetTitle}"');
    } on WonkyException catch (e) {
      throw _chartError(e);
    }
  }

  /// Whether the deck reaches people the spreadsheet doesn't (08 §6,
  /// 11 §8.3): a deck link without a spreadsheet link, or a deck owner or
  /// member without access to the spreadsheet.
  static Future<bool> broaderAudience(
    Session session,
    DriveItem deck,
    UuidValue spreadsheetUuid,
  ) async {
    final sheet = await AccessService.findItem(session, spreadsheetUuid);
    if (sheet == null) return false;
    final deckLink = await ShareLink.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(deck.id!),
    );
    final sheetLink = await ShareLink.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(sheet.id!),
    );
    if (deckLink?.role != null && sheetLink?.role == null) return true;
    final members = await DriveItemPermission.db.find(
      session,
      where: (t) => t.itemId.equals(deck.id!) & t.userId.notEquals(null),
      limit: 200,
    );
    final users = {deck.ownerId, for (final p in members) ?p.userId};
    for (final u in users) {
      if (await AccessService.effectiveRole(session, u, sheet) == null) {
        return true;
      }
    }
    return false;
  }

  static Future<ToolResult> insertLinkedChart(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    requireSheetsRead(ctx);
    final t = await SlidesMcp.edit(ctx, a);
    final spreadsheet = SlidesMcp.parseRef(
      a.requireString('spreadsheet'),
      what: 'spreadsheet',
    );
    final r = await _resolve(ctx, spreadsheet, a.requireString('chart_id'));
    final link = a.boolean('link') ?? true;
    final useDeckTheme = a.boolean('use_deck_theme') ?? true;
    final auto = a.boolean('auto_update') ?? false;
    final warnings = <SlidesWarning>[
      for (final w in r.warnings) SlidesWarning('chart_data', w),
    ];
    if (await broaderAudience(ctx.session, t.item, spreadsheet)) {
      warnings.add(
        const SlidesWarning(
          'broader_audience',
          'The presentation is shared more widely than the spreadsheet: '
              'people who can open the presentation will see this chart\'s data.',
        ),
      );
    }
    final snap = ChartSourceSnapshot.fromColumns(
      r.sourceSpecJson,
      r.dataSnapshotJson,
    );
    final title = snap.spec.title.hasText
        ? snap.spec.title.text
        : snap.dataSnapshot.source.chartTitle;
    final alt = ChartDescriber.describe(snap.spec, snap.data);
    String? elementId;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.insert_linked_chart',
      warnings: warnings,
      build: (s) {
        final m = s.model;
        final slideId = SlidesMcp.slideId(m, a.values['slide']);
        final frameArg = a.object('frame');
        final placement = a.object('placement');
        // An empty chart placeholder takes the chart (08 §4.2).
        if (frameArg == null && placement == null) {
          for (final e in SlidesMcp.placeholders(
            m,
            slideId,
            SlidePlaceholderType.chart,
          )) {
            if (m.chartLinkOf(e.id) != null || e.dataJson != null) continue;
            elementId = e.id;
            s.run(ChartLinkOps.link(e.id, r, autoUpdate: auto));
            s.run(
              SetChartStyle(e.id, {
                'style': {'useDeckTheme': useDeckTheme},
              }),
            );
            if (!link) s.run(UnlinkChart(e.id));
            s.run(
              SetElementProps(
                [e.id],
                altText: Patch(alt),
                elementName: title.isEmpty ? null : Patch(title),
              ),
            );
            return;
          }
        }
        final (sw, sh) = SlidesInput.slideSize(m);
        final w = sw * 0.7, h = sh * 0.7;
        final f = SlidesInput.frame(
          m,
          frame: frameArg,
          placement: placement,
          fallback: SuRect((sw - w) / 2, (sh - h) / 2, w, h),
          pointer: '/frame',
        );
        final data = ChartElementData(
          source: link ? SlideChartSource.linked : SlideChartSource.static,
          style: SlideChartStyle(useDeckTheme: useDeckTheme),
          snapshot: link ? null : snap,
        );
        final plan = s.run(
          InsertElements(slideId, [
            ElementSpec(
              kind: ElementKind.chart,
              x: f.x,
              y: f.y,
              width: f.width,
              height: f.height,
              columns: {
                ElementCols.dataJson: data.encode(),
                if (title.isNotEmpty) SlidesCols.name: title,
                ElementCols.altText: alt,
              },
            ),
          ]),
        );
        elementId = (plan.result['elementIds']! as List).single as String;
        if (link) {
          s.run(ChartLinkOps.link(elementId!, r, autoUpdate: auto));
        }
      },
    );
    return SlidesWrites.result(o, 'Inserted the chart "$title"', {
      'element_id': elementId,
      'linked': link,
    });
  }

  static Future<ToolResult> refreshLinkedCharts(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    requireSheetsRead(ctx);
    final t = await SlidesMcp.edit(ctx, a);
    final (o, r) = await refreshCharts(ctx, t, refs: a.list('elements'));
    final total =
        r['updated']!.length + r['up_to_date']!.length + r['failed']!.length;
    return SlidesWrites.result(
      o,
      'Updated ${r['updated']!.length} of $total linked charts',
      r,
    );
  }

  /// Updates linked charts ([refs], default all) from their spreadsheets;
  /// returns the outcome and `{updated, up_to_date, failed}`.
  static Future<(SlidesWriteOutcome, Map<String, List<Object?>>)> refreshCharts(
    ToolContext ctx,
    SlidesTarget t, {
    List<Object?>? refs,
  }) async {
    final m = t.model;
    final ids = refs == null || refs.isEmpty
        ? [
            for (final p in ChartLinkOps.probesOf(m))
              if (p.elementId case final String id) id,
          ]
        : SlidesMcp.elementIds(m, refs);
    final updated = <String>[];
    final upToDate = <String>[];
    final failed = <Map<String, Object?>>[];
    final ops = <SlidesOperation>[];
    for (final id in ids) {
      final link = m.chartLinkOf(id);
      if (link == null) {
        failed.add({'element_id': id, 'code': 'not_linked'});
        continue;
      }
      try {
        final r = await _resolve(
          ctx,
          UuidValue.withValidation(link.spreadsheetItemUuid),
          link.chartObjectId,
        );
        if (r.sourceVersion == link.sourceVersion) {
          upToDate.add(id);
          continue;
        }
        ops.add(ChartLinkOps.update(id, r));
        updated.add(id);
      } on McpToolException catch (e) {
        failed.add({'element_id': id, 'code': e.code});
      }
    }
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.refresh_linked_charts',
      warnings: [
        for (final f in failed)
          SlidesWarning(
            'chart_stale',
            'The chart could not be updated (${f['code']}).',
            elementId: f['element_id'] as String?,
          ),
      ],
      build: (s) {
        for (final op in ops) {
          s.run(op);
        }
      },
    );
    return (
      o,
      <String, List<Object?>>{
        'updated': updated,
        'up_to_date': upToDate,
        'failed': failed,
      },
    );
  }

  static Future<ToolResult> updateChartStyle(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await SlidesMcp.edit(ctx, a);
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.update_chart_style',
      build: (s) {
        final m = s.model;
        final id = SlidesMcp.elementId(m, a.values['element']);
        SlidesMcp.elementOfKind(m, id, {ElementKind.chart}, 'a chart');
        final overrides = a.object('overrides');
        if (overrides != null) {
          final rejected = ChartOverrides.rejectedPaths(
            SlidesInput.camel(overrides),
          );
          if (rejected.isNotEmpty) {
            throw SlidesMcp.invalid(
              'These overrides are not allowed: ${rejected.join(', ')}.',
              pointer: '/overrides',
            );
          }
        }
        final camera = a.object('camera');
        final patch = <String, Object?>{
          if (a.boolean('use_deck_theme') case final bool v)
            'style': {'useDeckTheme': v},
          if (camera != null) 'camera': SlidesInput.camel(camera),
          if (overrides != null) 'overrides': SlidesInput.camel(overrides),
          if (a.present('background')) 'background': a.string('background'),
        };
        if (patch.isEmpty) return;
        s.run(SetChartStyle(id, patch));
      },
    );
    return SlidesWrites.result(o, 'Updated the chart style');
  }

  static Future<ToolResult> unlinkChart(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.unlink_chart',
      build: (s) {
        final id = SlidesMcp.elementId(s.model, a.values['element']);
        if (s.model.chartLinkOf(id) == null) {
          throw McpToolException(
            SlidesErrorCode.invalidTarget,
            'Element $id is not a linked chart.',
          );
        }
        s.run(UnlinkChart(id));
      },
    );
    return SlidesWrites.result(o, 'Unlinked the chart');
  }
}
