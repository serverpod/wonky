import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write_core/wonky_write_core.dart' show AddressException;

import '../analytics/usage_tracker.dart';
import '../common/models.dart';
import '../common/rate_limiter.dart';
import 'tool_support.dart';

export '../common/rate_limiter.dart' show RateCounter, RedisRateCounter;

/// Rate limit per token (suite 09 §2: 600 tool calls per minute per
/// token): the generic [RateLimiter] under the `mcp` namespace.
class McpRateLimiter extends RateLimiter {
  McpRateLimiter({
    super.limit = 600,
    super.window = const Duration(minutes: 1),
    super.counter,
  }) : super(name: 'mcp');
}

/// A registered tool: its shared definition plus the implementation.
class RegisteredMcpTool {
  const RegisteredMcpTool(this.definition, this.handler);

  final McpToolDefinition definition;
  final ToolHandler handler;
}

/// Dispatches tool calls by name (suite 09 §3): looks the tool up, checks
/// the token's scopes, validates the arguments against the shared JSON
/// schema, applies the rate limit, runs the handler and maps every failure
/// to a structured error (`{code, message, details}`, suite 09 §7).
///
/// Handlers do their own permission checks through `AccessService` (the
/// effective role on the target item), exactly like the endpoints the apps
/// use.
class ToolExecutor {
  ToolExecutor(
    Iterable<RegisteredMcpTool> tools, {
    McpRateLimiter? rateLimiter,
    McpRateLimiter? targetWriteLimiter,
  }) : _tools = {for (final t in tools) t.definition.name: t},
       rateLimiter = rateLimiter ?? McpRateLimiter(),
       targetWriteLimiter =
           targetWriteLimiter ?? McpRateLimiter(limit: targetWriteLimit);

  final Map<String, RegisteredMcpTool> _tools;
  final McpRateLimiter rateLimiter;

  /// Mutating calls per minute per token and target file (Sheets 12 §3.14:
  /// 60 per spreadsheet; Slides 11 §3.13: 60 per deck), on top of the
  /// per-token limit.
  final McpRateLimiter targetWriteLimiter;

  static const targetWriteLimit = 60;

  /// Argument keys naming the file a mutating call writes to.
  static const _targetKeys = ['spreadsheet', 'deck'];
  static final _uuid = RegExp(
    '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
  );

  /// The tools in registration order.
  Iterable<RegisteredMcpTool> get tools => _tools.values;

  RegisteredMcpTool? operator [](String name) => _tools[name];

  /// Calls [name] with [arguments] as the token user of [ctx].
  Future<ToolOutcome> call(
    ToolContext ctx,
    String name,
    Map<String, Object?> arguments,
  ) async {
    final tool = _tools[name];
    if (tool == null) {
      return ToolOutcome.failure(
        McpToolException(
          McpErrorCode.notFound,
          'Unknown tool "$name". Call tools/list for the available tools.',
        ),
      );
    }
    final def = tool.definition;
    if (!ctx.hasAnyScope(def.scopes)) {
      return ToolOutcome.failure(
        McpToolException(
          McpErrorCode.forbidden,
          'The access token lacks the scope for $name '
          '(needs one of: ${def.scopes.join(', ')}).',
          details: {'required_scopes': def.scopes.toList()},
        ),
      );
    }
    final violations = def.inputSchema.validate(arguments);
    if (violations.isNotEmpty) {
      return ToolOutcome.failure(
        McpToolException.invalidArgs(
          'Invalid arguments for $name: ${violations.first}',
          violations: violations,
        ),
      );
    }
    final retry = await rateLimiter.check(
      ctx.tokenId ?? 'user:${ctx.actor.userId}',
    );
    if (retry != null) {
      return ToolOutcome.failure(
        McpToolException(
          McpErrorCode.rateLimited,
          'Too many tool calls; retry in ${retry.inSeconds + 1} s.',
          details: {'retry_after_ms': retry.inMilliseconds},
        ),
      );
    }
    final target = _writeTarget(def, arguments);
    if (target != null && ctx.tokenId != null) {
      final wait = await targetWriteLimiter.check(
        'token:${ctx.tokenId}:target:$target',
      );
      if (wait != null) {
        return ToolOutcome.failure(
          McpToolException(
            McpErrorCode.rateLimited,
            'Too many changes to this file (at most $targetWriteLimit per '
            'minute); retry in ${wait.inSeconds + 1} s.',
            details: {
              'retry_after_ms': wait.inMilliseconds,
              'limit': targetWriteLimit,
            },
          ),
        );
      }
    }
    // Usage analytics (specs/19 §2): people's tokens, not the assistant.
    if (ctx.actor.kind == ActorKind.mcp) {
      await UsageTracker.mcpCall(ctx.session, ctx.actor.userId);
    }
    try {
      final result = await tool.handler(ctx, ToolArgs(arguments));
      return ToolOutcome.success(result);
    } on McpToolException catch (e) {
      return ToolOutcome.failure(e);
    } on AddressException catch (e) {
      return ToolOutcome.failure(
        McpToolException(e.code, e.message, details: e.details),
      );
    } on WonkyException catch (e) {
      return ToolOutcome.failure(McpToolException.fromWonky(e));
    } on Exception catch (e, st) {
      ctx.session.log(
        'MCP tool $name failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return ToolOutcome.failure(
        McpToolException(McpErrorCode.internal, 'The tool failed: $e'),
      );
    } on Error catch (e, st) {
      ctx.session.log(
        'MCP tool $name crashed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return ToolOutcome.failure(
        McpToolException(McpErrorCode.internal, 'The tool failed.'),
      );
    }
  }

  /// The file a mutating call of [def] writes to (null for read-only tools
  /// and tools without a target argument).
  static String? _writeTarget(
    McpToolDefinition def,
    Map<String, Object?> arguments,
  ) {
    if (def.annotations.readOnly) return null;
    for (final k in _targetKeys) {
      final v = arguments[k];
      if (v is String && v.trim().isNotEmpty) {
        // A URL and the bare uuid count as the same file.
        final t = v.trim().toLowerCase();
        return _uuid.firstMatch(t)?.group(0) ?? t;
      }
    }
    return null;
  }
}
