import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:wonky_core/files.dart' show formatStorageBytes;
import 'package:wonky_core/wonky_core.dart' show McpScope;

import '../common/models.dart';
import '../drive/drive_service.dart';
import '../storage/storage_service.dart';
import 'drive_file_tool_handlers.dart';
import 'tool_support.dart';
import 'mcp_errors.dart';
import 'wonky_mcp_server.dart';

/// (v2) Drive MCP resources (suite 09 §5): `wonky://drive/storage` (usage
/// JSON, like `drive.get_storage`) and `wonky://file/<uuid>` (an uploaded
/// file: text files up to 1 MB as text, other files up to 2 MB as a blob;
/// larger files are read with `drive.download_file` and `as: url`).
abstract final class DriveMcpContent {
  static const fileTemplate = 'wonky://file/{uuid}';

  static void registerResources(mcp.McpServer server, ToolContextLookup ctxOf) {
    server.registerResource(
      'Storage',
      'wonky://drive/storage',
      (
        description:
            'The user\'s storage usage: quota, used, reserved and available '
            'bytes, usage by kind (drive.get_storage).',
        mimeType: 'application/json',
      ),
      (uri, extra) async {
        final ctx = ctxOf(extra);
        return readStorage(ctx, uri);
      },
    );
    server.registerResourceTemplate(
      'Uploaded file',
      mcp.ResourceTemplateRegistration(
        fileTemplate,
        listCallback: _listFiles(ctxOf),
      ),
      (
        description:
            'An uploaded file: text files up to 1 MB as text, other files up '
            'to 2 MB as a base64 blob.',
        mimeType: null,
      ),
      (uri, vars, extra) async {
        final ctx = ctxOf(extra);
        return readFile(ctx, uri, '${vars['uuid']}');
      },
    );
  }

  /// `wonky://drive/storage`.
  static Future<mcp.ReadResourceResult> readStorage(
    ToolContext ctx,
    Uri uri,
  ) async {
    _scope(ctx, McpScope.driveRead);
    final usage = await StorageService.instance.usage(
      ctx.session,
      ctx.actor.userId,
    );
    return mcp.ReadResourceResult(
      contents: [
        mcp.TextResourceContents(
          uri: uri.toString(),
          mimeType: 'application/json',
          text: const JsonEncoder.withIndent(
            '  ',
          ).convert(DriveFileToolHandlers.usageJson(usage)),
        ),
      ],
    );
  }

  /// `wonky://file/<uuid>`.
  static Future<mcp.ReadResourceResult> readFile(
    ToolContext ctx,
    Uri uri,
    String uuid,
  ) async {
    _scope(ctx, McpScope.driveRead);
    final UuidValue id;
    try {
      id = UuidValue.withValidation(uuid);
    } on FormatException {
      throw mcp.McpError(
        mcp.ErrorCode.resourceNotFound.value,
        'Unknown file.',
      );
    }
    return McpErrors.guardResource(() async {
      final c = await DriveFileToolHandlers.readable(ctx, id);
      final asText =
          c.isText && c.sizeBytes <= DriveFileToolHandlers.textMaxBytes;
      if (!asText && c.sizeBytes > DriveFileToolHandlers.base64MaxBytes) {
        throw McpToolException(
          McpErrorCode.tooLarge,
          '"${c.item.name}" is ${formatStorageBytes(c.sizeBytes)}; read it '
          'with drive.download_file (as: url).',
        );
      }
      final bytes = await DriveFileToolHandlers.bytesOf(ctx.session, c);
      return mcp.ReadResourceResult(
        contents: [
          if (asText)
            mcp.TextResourceContents(
              uri: uri.toString(),
              mimeType: c.mimeType,
              text: DriveFileToolHandlers.decodeText(bytes, c.encoding!),
            )
          else
            mcp.BlobResourceContents(
              uri: uri.toString(),
              mimeType: c.mimeType,
              blob: base64Encode(bytes),
            ),
        ],
      );
    });
  }

  /// The 50 most recently modified uploaded files.
  static mcp.ListResourcesCallback _listFiles(
    ToolContextLookup ctxOf,
  ) => (extra) async {
    final ctx = ctxOf(extra);
    if (!ctx.scopes.contains(McpScope.driveRead)) {
      return const mcp.ListResourcesResult(resources: []);
    }
    final page = await DriveService.list(
      ctx.session,
      ctx.actor,
      filter: DriveListFilter(
        view: DriveView.recent,
        kinds: [DriveItemKind.file],
      ),
      sort: DriveSort(field: DriveSortField.modifiedAt),
      limit: 50,
    );
    return mcp.ListResourcesResult(
      resources: [
        for (final v in page.items)
          if (v.uploadState == null || v.uploadState == FileUploadState.ready)
            mcp.Resource(
              uri: 'wonky://file/${v.uuid.uuid}',
              name: v.name,
              description: 'Uploaded file (${formatStorageBytes(v.sizeBytes)})',
              mimeType: v.mimeType,
            ),
      ],
    );
  };

  static void _scope(ToolContext ctx, String scope) {
    if (!ctx.scopes.contains(scope)) {
      throw mcp.McpError(
        mcp.ErrorCode.invalidRequest.value,
        'The access token lacks the $scope scope.',
      );
    }
  }

  /// Maps tool errors to JSON-RPC errors for resource reads.
}
