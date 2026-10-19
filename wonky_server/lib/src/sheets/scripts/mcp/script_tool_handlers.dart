import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:wonky_core/wonky_core.dart'
    show McpScope, McpToolDefinition, Role, SheetsScriptTools;
import 'package:wonky_sheets_script/wonky_sheets_script.dart'
    show ScriptDiagnostic, ScriptExports;

import '../../../platform/common/models.dart';
import '../../../platform/mcp/tool_executor.dart';
import '../../../platform/mcp/tool_support.dart';
import '../../mcp/sheets_mcp_support.dart';
import '../script_service.dart';
import '../script_executions.dart';

/// Handlers of the script tools (`sheets.list_script_functions`,
/// `sheets.run_function`, `sheets.get_script_files`,
/// `sheets.update_script_file`, `sheets.delete_script_file`,
/// `sheets.get_executions`; Sheets 09 §18).
abstract final class ScriptToolHandlers {
  static List<RegisteredMcpTool> get all => [
    _t(SheetsScriptTools.listFunctions, listFunctions),
    _t(SheetsScriptTools.runFunction, runFunction),
    _t(SheetsScriptTools.getFiles, getFiles),
    _t(SheetsScriptTools.updateFile, updateFile),
    _t(SheetsScriptTools.deleteFile, deleteFile),
    _t(SheetsScriptTools.getExecutions, getExecutions),
  ];

  static RegisteredMcpTool _t(McpToolDefinition d, ToolHandler h) =>
      RegisteredMcpTool(d, (ctx, a) async {
        try {
          ScriptService.requireEnabled();
        } on WonkyException catch (e) {
          throw McpToolException(McpErrorCode.unavailable, e.message);
        }
        return h(ctx, a);
      });

  static void _requireEdit(ToolContext ctx) {
    if (!ctx.hasAnyScope({McpScope.sheetsEdit})) {
      throw McpToolException(
        McpErrorCode.forbidden,
        'Editing scripts needs the sheets:edit scope as well.',
        details: {
          'required_scopes': [McpScope.sheetsEdit],
        },
      );
    }
  }

  static Future<ToolResult> listFunctions(ToolContext ctx, ToolArgs a) async {
    final (item, _) = await SheetsMcp.resolveItem(
      ctx.session,
      ctx,
      a.requireString('spreadsheet'),
    );
    final space = item.contentRef!;
    final p = await ScriptService.project(ctx.session, space);
    if (p == null) {
      return const ToolResult(
        {'build': null, 'functions': <Object?>[], 'triggers': <Object?>[]},
        text: 'This spreadsheet has no script.',
      );
    }
    final b = await ScriptService.build(ctx.session, p.id);
    final exports = b?.lastGoodExportsJson == null
        ? ScriptExports.empty
        : ScriptExports.decode(b!.lastGoodExportsJson!);
    final macros = await Macro.db.find(
      ctx.session,
      where: (t) => t.projectId.equals(p.id),
    );
    final triggers = await ScriptTrigger.db.find(
      ctx.session,
      where: (t) => t.projectId.equals(p.id),
    );
    final errors = b == null
        ? 0
        : ScriptDiagnostic.decodeList(
            b.diagnosticsJson,
          ).where((d) => d.isError).length;
    final functions = [
      for (final f in exports.functions)
        {
          'name': f.name,
          'params': [for (final p in f.params) p.toJson()],
          'doc': f.doc,
          'kind': f.customFunction != null
              ? 'customFunction'
              : exports.triggers.containsKey(f.name)
              ? 'trigger'
              : macros.any((m) => m.functionName == f.name)
              ? 'macro'
              : 'runnable',
          if (f.customFunction != null)
            'formula_name': f.customFunction!.formulaName,
          for (final m in macros)
            if (m.functionName == f.name)
              'macro': {'name': m.name, 'shortcut': m.shortcutSlot},
          'runnable': f.runnable,
        },
    ];
    return ToolResult({
      'build': b == null
          ? null
          : {
              'source_hash': b.sourceHash,
              'built_at': b.builtAt.toUtc().toIso8601String(),
              'status': b.status.name,
              'errors': errors,
            },
      'functions': functions,
      'triggers': [
        for (final t in triggers)
          {
            'id': t.id.uuid,
            'function': t.functionName,
            'event': t.kind.name,
            'schedule': t.scheduleJson == null
                ? null
                : jsonDecode(t.scheduleJson!),
            'enabled': t.enabled,
          },
      ],
    }, text: '${functions.length} functions, ${triggers.length} triggers.');
  }

  static Future<ToolResult> runFunction(ToolContext ctx, ToolArgs a) async {
    final (item, _) = await SheetsMcp.resolveItem(
      ctx.session,
      ctx,
      a.requireString('spreadsheet'),
    );
    final timeout = a.integer('timeout_s');
    final ScriptRunResponse r;
    try {
      r = await ScriptService.run(
        ctx.session,
        ctx.actor,
        item.uuid,
        a.requireString('function'),
        args: [...?a.list('args')],
        kind: ScriptExecutionKind.mcp,
        timeout: timeout == null
            ? null
            : Duration(seconds: timeout.clamp(1, 360)),
      );
    } on WonkyException catch (e) {
      // Agents cannot authorize scripts (09 §11.2).
      if (e.message.startsWith('authorization_required')) {
        throw McpToolException('authorization_required', e.message);
      }
      rethrow;
    }
    final error = r.errorJson == null ? null : jsonDecode(r.errorJson!);
    return ToolResult(
      {
        'status': r.status.name,
        'result': r.resultJson == null ? null : jsonDecode(r.resultJson!),
        'logs': [
          for (final l in const LineSplitter().convert(r.logs))
            if (l.isNotEmpty) jsonDecode(l),
        ],
        'error': ?error,
        'change_id': r.changeId?.uuid,
        'execution_id': r.executionId.uuid,
        'cells_written': r.cellsWritten,
      },
      text:
          'Status ${r.status.name}${r.changeId == null ? '' : ' · change_id ${r.changeId!.uuid}'}',
    );
  }

  static Future<ToolResult> getFiles(ToolContext ctx, ToolArgs a) async {
    final (item, _) = await SheetsMcp.resolveItem(
      ctx.session,
      ctx,
      a.requireString('spreadsheet'),
    );
    final p = await ScriptService.project(ctx.session, item.contentRef!);
    final names = a.list('names')?.map((e) => '$e').toSet();
    final files = p == null
        ? const <ScriptFile>[]
        : await ScriptService.files(ctx.session, p.id);
    return ToolResult({
      'files': [
        for (final f in files)
          if (names == null || names.contains(f.name))
            {
              'name': f.name,
              'source': f.source,
              'content_hash': f.contentHash,
              'updated_by': f.updatedBy.uuid,
              'updated_at': f.updatedAt.toUtc().toIso8601String(),
            },
      ],
    });
  }

  static Future<ToolResult> updateFile(ToolContext ctx, ToolArgs a) async {
    _requireEdit(ctx);
    final (item, _) = await SheetsMcp.resolveItem(
      ctx.session,
      ctx,
      a.requireString('spreadsheet'),
      min: Role.editor,
    );
    final name = a.requireString('name');
    final hash = await ScriptService.writeFile(
      ctx.session,
      ctx.actor,
      item,
      name,
      a.requireString('source'),
      baseHash: a.string('base_hash'),
      createIfMissing: a.boolean('create_if_missing') ?? false,
    );
    final build = await ScriptService.compile(
      ctx.session,
      ctx.actor,
      item.uuid,
    );
    final diagnostics = jsonDecode(build.diagnosticsJson) as List;
    return ToolResult(
      {
        'content_hash': hash,
        'build': {
          'status': build.ok ? 'ok' : 'errors',
          'diagnostics': diagnostics,
        },
      },
      text: build.ok
          ? 'Saved $name; the script builds.'
          : 'Saved $name; the build has ${diagnostics.length} problems.',
    );
  }

  static Future<ToolResult> deleteFile(ToolContext ctx, ToolArgs a) async {
    _requireEdit(ctx);
    final (item, _) = await SheetsMcp.resolveItem(
      ctx.session,
      ctx,
      a.requireString('spreadsheet'),
      min: Role.editor,
    );
    await ScriptService.deleteFile(
      ctx.session,
      ctx.actor,
      item,
      a.requireString('name'),
    );
    await ScriptService.compile(ctx.session, ctx.actor, item.uuid);
    return const ToolResult({'ok': true});
  }

  static Future<ToolResult> getExecutions(ToolContext ctx, ToolArgs a) async {
    final (item, _) = await SheetsMcp.resolveItem(
      ctx.session,
      ctx,
      a.requireString('spreadsheet'),
    );
    final cursor = a.string('cursor');
    final status = a.string('status');
    final limit = a.integer('limit') ?? 20;
    final rows = await ScriptExecutions.executions(
      ctx.session,
      ctx.actor,
      item.uuid,
      functionName: a.string('function'),
      status: status == null
          ? null
          : ScriptExecutionStatus.values.byName(status),
      before: cursor == null ? null : DateTime.tryParse(cursor),
      limit: limit,
    );
    String clip(String s) =>
        s.length <= 10240 ? s : '${s.substring(0, 10240)}…';
    return ToolResult({
      'executions': [
        for (final e in rows)
          {
            'execution_id': e.uuid.uuid,
            'function': e.functionName,
            'kind': e.kind.name,
            'status': e.status.name,
            'started_at': e.startedAt.toUtc().toIso8601String(),
            'duration_ms': e.durationMs,
            'runtime': e.runtime.name,
            'error': e.errorMessage,
            'logs': clip(e.logs),
            'cells_written': e.cellsWritten,
            'change_id': e.changeId?.uuid,
          },
      ],
      'next_cursor': rows.length < limit
          ? null
          : rows.last.startedAt.toUtc().toIso8601String(),
      'as_of': clock.now().toUtc().toIso8601String(),
    });
  }
}
