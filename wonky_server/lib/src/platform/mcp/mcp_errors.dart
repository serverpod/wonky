import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart' as mcp;

import '../common/models.dart';
import 'tool_support.dart';

/// The one mapping between tool errors ([McpToolException]), endpoint
/// errors ([WonkyException]) and MCP protocol errors (CQ-51): used by the
/// AI services, which call the shared MCP helpers from endpoints, and by
/// the MCP resources and prompts of every app.
abstract final class McpErrors {
  /// The endpoint exception of a tool error (the inverse of
  /// [McpToolException.fromWonky]); `detailsJson` is `{code, details}`.
  static WonkyException toWonky(McpToolException e) => WonkyException(
    code: switch (e.code) {
      McpErrorCode.notFound => WonkyErrorCode.notFound,
      McpErrorCode.forbidden => WonkyErrorCode.forbidden,
      McpErrorCode.busy => WonkyErrorCode.busy,
      McpErrorCode.conflict ||
      McpErrorCode.revisionMismatch ||
      McpErrorCode.beingEdited => WonkyErrorCode.conflict,
      McpErrorCode.tooLarge => WonkyErrorCode.tooLarge,
      McpErrorCode.rateLimited => WonkyErrorCode.limitExceeded,
      McpErrorCode.expired => WonkyErrorCode.expired,
      McpErrorCode.unavailable => WonkyErrorCode.unavailable,
      McpErrorCode.quotaExceeded => WonkyErrorCode.quotaExceeded,
      _ => WonkyErrorCode.invalidArgument,
    },
    message: e.message,
    detailsJson: jsonEncode({'code': e.code, 'details': e.details}),
  );

  /// Runs [body] for an endpoint: tool errors become [WonkyException]s.
  static Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on McpToolException catch (e) {
      throw toWonky(e);
    }
  }

  /// [guard] for synchronous helpers.
  static T guardSync<T>(T Function() body) {
    try {
      return body();
    } on McpToolException catch (e) {
      throw toWonky(e);
    }
  }

  /// The protocol error of a tool error (`resourceNotFound` for
  /// `not_found`, else `invalidParams`; data = the tool error JSON).
  static mcp.McpError toProtocol(McpToolException e) => mcp.McpError(
    e.code == McpErrorCode.notFound
        ? mcp.ErrorCode.resourceNotFound.value
        : mcp.ErrorCode.invalidParams.value,
    e.message,
    e.toJson(),
  );

  /// Runs [body] for an MCP resource or prompt: tool and service errors
  /// become protocol errors.
  static Future<T> guardResource<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on McpToolException catch (e) {
      throw toProtocol(e);
    } on WonkyException catch (e) {
      throw toProtocol(McpToolException.fromWonky(e));
    }
  }
}
