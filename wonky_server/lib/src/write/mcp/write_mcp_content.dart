import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart' show McpScope;

import '../../platform/common/models.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/mcp/collab_tool_handlers.dart';
import '../../platform/mcp/drive_tool_handlers.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/mcp/mcp_errors.dart';
import '../../platform/mcp/wonky_mcp_server.dart';
import 'headless_editor.dart';
import 'write_tool_handlers.dart';

/// MCP resources and prompts (suite 09 §5, Write 09 §4):
/// `wonky://drive/recent`, `wonky://doc/<uuid>` (Markdown, accepted view),
/// `wonky://doc/<uuid>/outline`, `wonky://doc/<uuid>/delta` and
/// `wonky://doc/<uuid>/comments`, plus thin prompt templates that point the
/// model at them.
abstract final class WriteMcpContent {
  static const docTemplate = 'wonky://doc/{uuid}';

  static void registerResources(mcp.McpServer server, ToolContextLookup ctxOf) {
    server.registerResource(
      'Recent items',
      'wonky://drive/recent',
      (
        description: 'The 50 drive items the user opened most recently.',
        mimeType: 'application/json',
      ),
      (uri, extra) async {
        final ctx = ctxOf(extra);
        _scope(ctx, McpScope.driveRead);
        final page = await McpErrors.guardResource(
          () => DriveService.list(
            ctx.session,
            ctx.actor,
            filter: DriveListFilter(view: DriveView.recent),
            sort: DriveSort(field: DriveSortField.lastOpenedByMe),
            limit: 50,
          ),
        );
        return _json(uri, {
          'items': [for (final v in page.items) DriveToolHandlers.itemJson(v)],
        });
      },
    );

    mcp.ResourceTemplateRegistration template(String pattern) =>
        mcp.ResourceTemplateRegistration(
          pattern,
          listCallback: pattern == docTemplate ? _listDocuments(ctxOf) : null,
        );

    server.registerResourceTemplate(
      'Document',
      template(docTemplate),
      (
        description:
            'A Wonky Write document as Markdown (pending suggestions '
            'accepted, with front matter).',
        mimeType: 'text/markdown',
      ),
      (uri, vars, extra) async {
        final ctx = ctxOf(extra);
        _scope(ctx, McpScope.writeRead);
        final r = await McpErrors.guardResource(
          () => WriteToolHandlers.getDocument(
            ctx,
            ToolArgs({'document_uuid': '${vars['uuid']}', 'max_chars': 200000}),
          ),
        );
        return mcp.ReadResourceResult(
          contents: [
            mcp.TextResourceContents(
              uri: uri.toString(),
              mimeType: 'text/markdown',
              text: (r.structured! as Map)['content'] as String,
            ),
          ],
        );
      },
    );

    server.registerResourceTemplate(
      'Document outline',
      template('wonky://doc/{uuid}/outline'),
      (
        description: 'The headings of a document (write.get_outline).',
        mimeType: 'application/json',
      ),
      (uri, vars, extra) async {
        final ctx = ctxOf(extra);
        _scope(ctx, McpScope.writeRead);
        final r = await McpErrors.guardResource(
          () => WriteToolHandlers.getOutline(
            ctx,
            ToolArgs({'document_uuid': '${vars['uuid']}'}),
          ),
        );
        return _json(uri, r.structured);
      },
    );

    server.registerResourceTemplate(
      'Document delta',
      template('wonky://doc/{uuid}/delta'),
      (
        description:
            'The raw Quill Delta of a document (with comment and '
            'suggestion overlays) and its revision.',
        mimeType: 'application/json',
      ),
      (uri, vars, extra) async {
        final ctx = ctxOf(extra);
        _scope(ctx, McpScope.writeRead);
        final t = await McpErrors.guardResource(
          () => HeadlessDocumentEditor.resolve(
            ctx.session,
            ctx.actor,
            mcpUuid('${vars['uuid']}'),
          ),
        );
        final state = await HeadlessDocumentEditor.head(
          ctx.session,
          t.document,
        );
        return _json(uri, {
          'document_uuid': t.item.uuid.uuid,
          'revision': state.revision,
          'delta': state.content.toJson(),
        });
      },
    );

    server.registerResourceTemplate(
      'Document comments',
      template('wonky://doc/{uuid}/comments'),
      (
        description: 'Open comment threads of a document with anchors.',
        mimeType: 'application/json',
      ),
      (uri, vars, extra) async {
        final ctx = ctxOf(extra);
        _scope(ctx, McpScope.writeRead);
        final r = await McpErrors.guardResource(
          () => CollabToolHandlers.listComments(
            ctx,
            ToolArgs({'uuid': '${vars['uuid']}', 'status': 'open'}),
          ),
        );
        return _json(uri, r.structured);
      },
    );
  }

  static mcp.ListResourcesCallback _listDocuments(ToolContextLookup ctxOf) =>
      (extra) async {
        final ctx = ctxOf(extra);
        if (!ctx.scopes.contains(McpScope.writeRead)) {
          return const mcp.ListResourcesResult(resources: []);
        }
        final page = await DriveService.list(
          ctx.session,
          ctx.actor,
          filter: DriveListFilter(
            view: DriveView.recent,
            kinds: [DriveItemKind.document],
          ),
          sort: DriveSort(field: DriveSortField.lastOpenedByMe),
          limit: 50,
        );
        return mcp.ListResourcesResult(
          resources: [
            for (final v in page.items)
              mcp.Resource(
                uri: 'wonky://doc/${v.uuid.uuid}',
                name: v.name,
                description: 'Wonky Write document (Markdown)',
                mimeType: 'text/markdown',
              ),
          ],
        );
      };

  static mcp.ReadResourceResult _json(Uri uri, Object? value) =>
      mcp.ReadResourceResult(
        contents: [
          mcp.TextResourceContents(
            uri: uri.toString(),
            mimeType: 'application/json',
            text: const JsonEncoder.withIndent('  ').convert(value),
          ),
        ],
      );

  static void _scope(ToolContext ctx, String scope) {
    if (!ctx.scopes.contains(scope)) {
      throw mcp.McpError(
        mcp.ErrorCode.invalidRequest.value,
        'The access token lacks the $scope scope.',
      );
    }
  }

  /// Maps tool errors to JSON-RPC errors for resource reads.

  static UuidValue mcpUuid(String s) {
    try {
      return UuidValue.withValidation(s);
    } on FormatException {
      throw McpToolException(McpErrorCode.notFound, 'Unknown document.');
    }
  }

  // --------------------------------------------------------------- prompts

  static void registerPrompts(mcp.McpServer server) {
    const uuidArg = mcp.PromptArgumentDefinition(
      description: 'Document uuid (from drive.search or a /d/<uuid> URL).',
      required: true,
    );
    mcp.GetPromptResult prompt(String description, String text) =>
        mcp.GetPromptResult(
          description: description,
          messages: [
            mcp.PromptMessage(
              role: mcp.PromptMessageRole.user,
              content: mcp.TextContent(text: text),
            ),
          ],
        );
    String doc(Map<String, dynamic>? args) => '${args?['uuid'] ?? ''}';

    server.registerPrompt(
      'summarize_document',
      title: 'Summarize a document',
      description: 'Summarize a Wonky Write document.',
      argsSchema: {'uuid': uuidArg},
      callback: (args, extra) => prompt(
        'Summarize a document',
        'Read the document wonky://doc/${doc(args)} (or call '
            'write.get_document with document_uuid "${doc(args)}") and write '
            'a concise summary: the purpose, the key points per section and '
            'any open questions. Do not edit the document.',
      ),
    );
    server.registerPrompt(
      'review_document',
      title: 'Review a document',
      description: 'Review a document and leave comments.',
      argsSchema: {'uuid': uuidArg},
      callback: (args, extra) => prompt(
        'Review a document',
        'Review the document wonky://doc/${doc(args)} for clarity, '
            'structure and correctness. Leave each finding as a comment '
            '(comments.create with a short exact quote anchor). Do not edit '
            'the text. Finish with a short overall assessment.',
      ),
    );
    server.registerPrompt(
      'proofread_document',
      title: 'Proofread a document',
      description: 'Fix spelling and grammar as suggestions.',
      argsSchema: {'uuid': uuidArg},
      callback: (args, extra) => prompt(
        'Proofread a document',
        'Proofread wonky://doc/${doc(args)}. For each spelling, grammar or '
            'punctuation error call write.replace_text with mode "suggest", '
            'the exact wrong text as find and its occurrence (use '
            'write.search to get occurrences). Keep the author\'s style; do '
            'not rewrite correct sentences.',
      ),
    );
    server.registerPrompt(
      'rewrite_section',
      title: 'Rewrite a section',
      description:
          'Rewrite one section of a document following an instruction.',
      argsSchema: {
        'uuid': uuidArg,
        'heading': const mcp.PromptArgumentDefinition(
          description: 'The heading of the section.',
          required: true,
        ),
        'instruction': const mcp.PromptArgumentDefinition(
          description: 'How to rewrite it ("make it shorter", …).',
          required: true,
        ),
      },
      callback: (args, extra) => prompt(
        'Rewrite a section',
        'In document ${doc(args)}, read the section "${args?['heading']}" '
            '(write.get_document with range {"type":"heading_section",'
            '"heading":"${args?['heading']}"}) and rewrite it: '
            '${args?['instruction']}. Apply the result with '
            'write.replace_range on that heading_section range (keep the '
            'heading) and report the change_id.',
      ),
    );
    server.registerPrompt(
      'draft_from_outline',
      title: 'Draft from the outline',
      description: 'Write body text under each heading of a document.',
      argsSchema: {'uuid': uuidArg},
      callback: (args, extra) => prompt(
        'Draft from the outline',
        'Read the outline of ${doc(args)} (write.get_outline). For each '
            'section without body text, draft 1–3 paragraphs and insert them '
            'with write.insert_markdown at {"type":"end_of_section",'
            '"heading":…}. Keep the existing headings unchanged.',
      ),
    );
  }
}
