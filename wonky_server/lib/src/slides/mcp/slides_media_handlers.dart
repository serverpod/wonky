import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides_core/markdown.dart' show DeckOutlineCodec;

import '../../platform/mcp/tool_support.dart';
import '../exports/slides_export_service.dart';
import 'slides_input.dart';
import 'slides_chart_handlers.dart';
import 'slides_mcp_support.dart';

/// Export tools of decks (Slides 11 §3): PDF and the Drive export. Charts,
/// code blocks and builds are in [SlidesChartHandlers], [SlidesCodeHandlers]
/// and [SlidesBuildHandlers].
abstract final class SlidesMediaHandlers {
  static Future<ToolResult> exportPdf(ToolContext ctx, ToolArgs a) async {
    var t = await SlidesMcp.open(ctx, a);
    Map<String, Object?>? refreshed;
    if (a.boolean('refresh_linked_charts') ?? false) {
      if (!t.canEdit) {
        throw McpToolException(
          McpErrorCode.forbidden,
          'Only editors can update linked charts before exporting.',
        );
      }
      SlidesChartHandlers.requireSheetsRead(ctx);
      final (o, r) = await SlidesChartHandlers.refreshCharts(ctx, t);
      refreshed = {...r, 'change_id': o.write.changeId?.uuid};
      t = await SlidesMcp.open(ctx, a);
    }
    final options = SlidesInput.camel(a.object('options') ?? const {});
    final view = await SlidesExportService.export(
      ctx.session,
      ctx.actor,
      t.item.uuid,
      'pdf',
      jsonEncode(options),
    );
    return ToolResult(
      {
        'format': 'pdf',
        'file_name': view.fileName,
        'mime_type': view.mimeType,
        'size_bytes': view.sizeBytes,
        'page_count': view.pageCount,
        'download_url': view.downloadUrl,
        'expires_at': view.expiresAt.toIso8601String(),
        'warnings': [
          for (final w in view.warnings) {'code': w.kind, 'message': w.message},
        ],
        'refreshed_charts': ?refreshed,
      },
      text: 'Download: ${view.downloadUrl} (valid until ${view.expiresAt})',
    );
  }

  /// `drive.export` of a presentation (11 §3.12): `pdf` (as export_pdf),
  /// `md` (the outline Markdown, inline).
  static Future<ToolResult> driveExport(
    ToolContext ctx,
    UuidValue uuid,
    String format,
  ) async {
    final t = await SlidesMcp.openRef(ctx, uuid.uuid);
    switch (format) {
      case 'pdf':
        return exportPdf(ctx, ToolArgs({'deck': uuid.uuid}));
      case 'md':
        if (t.role < Role.editor && !t.item.nonEditorsCanExport) {
          throw McpToolException(
            McpErrorCode.forbidden,
            'The owner has disabled downloads for viewers.',
          );
        }
        final md = DeckOutlineCodec.write(t.model);
        return ToolResult({
          'format': 'md',
          'file_name': '${t.item.name}.md',
          'mime_type': 'text/markdown',
          'size_bytes': utf8.encode(md).length,
          'content': md,
        }, text: md);
      default:
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'Presentations export as pdf or md.',
        );
    }
  }
}
