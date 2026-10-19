// Named parameters can't initialize private fields directly.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show JsonSchemaViolation;
import 'package:wonky_write_core/wonky_write_core.dart' show Delta;

import '../common/actor.dart';
import '../common/models.dart';

/// MCP tool error codes (suite 09 §7, Write 09 §1.3).
abstract final class McpErrorCode {
  static const notFound = 'not_found';
  static const forbidden = 'forbidden';
  static const invalidArgs = 'invalid_args';
  static const conflict = 'conflict';
  static const revisionMismatch = 'revision_mismatch';
  static const validationFailed = 'validation_failed';
  static const tooLarge = 'too_large';
  static const rateLimited = 'rate_limited';
  static const unavailable = 'unavailable';
  static const unsupported = 'unsupported';
  static const unsupportedInSuggestMode = 'unsupported_in_suggest_mode';
  static const expired = 'expired';
  static const busy = 'busy';
  static const internal = 'internal_error';

  /// A per-call limit (details: `{limit, max}`); shared by the app tools.
  static const limitExceeded = 'limit_exceeded';

  /// Someone else is editing the target (Slides soft locks).
  static const beingEdited = 'being_edited';

  /// (v2) Not enough storage (Drive 03 §6.6); details are
  /// `QuotaExceededDetails`.
  static const quotaExceeded = 'quota_exceeded';

  /// UI bridge (suite 09 §6).
  static const noSession = 'no_session';
  static const timeout = 'timeout';
  static const stoppedByUser = 'stopped_by_user';
}

/// A structured tool failure: returned as `isError: true` with the JSON
/// payload `{code, message, details}` (suite 09 §7).
class McpToolException implements Exception {
  McpToolException(this.code, this.message, {this.details});

  final String code;
  final String message;
  final Object? details;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    if (details != null) 'details': details,
  };

  static McpToolException invalidArgs(
    String message, {
    List<JsonSchemaViolation> violations = const [],
  }) => McpToolException(
    McpErrorCode.invalidArgs,
    message,
    details: violations.isEmpty
        ? null
        : [
            for (final v in violations)
              {'pointer': _pointer(v.path), 'message': v.message},
          ],
  );

  /// A per-call limit was exceeded: [message] plus `{limit, max}`
  /// details (Sheets 12 §3.14, Slides 11 §2.3).
  static McpToolException limit(
    String message, {
    required String limit,
    required int max,
  }) => McpToolException(
    McpErrorCode.limitExceeded,
    message,
    details: {'limit': limit, 'max': max},
  );

  /// `$.range.quote` → `/range/quote`.
  static String _pointer(String path) {
    final p = path.startsWith(r'$') ? path.substring(1) : path;
    return p
        .replaceAllMapped(RegExp(r'\[(\d+)\]'), (m) => '.${m[1]}')
        .replaceAll('.', '/');
  }

  /// Maps a service [WonkyException] to a tool error.
  static McpToolException fromWonky(WonkyException e) {
    final code = switch (e.code) {
      WonkyErrorCode.notFound => McpErrorCode.notFound,
      WonkyErrorCode.forbidden => McpErrorCode.forbidden,
      WonkyErrorCode.invalidArgument => McpErrorCode.invalidArgs,
      WonkyErrorCode.conflict => McpErrorCode.conflict,
      WonkyErrorCode.tooLarge => McpErrorCode.tooLarge,
      WonkyErrorCode.limitExceeded => McpErrorCode.rateLimited,
      WonkyErrorCode.expired => McpErrorCode.expired,
      WonkyErrorCode.unavailable => McpErrorCode.unavailable,
      WonkyErrorCode.busy => McpErrorCode.busy,
      WonkyErrorCode.quotaExceeded => McpErrorCode.quotaExceeded,
      _ => e.code.name,
    };
    Object? details;
    final raw = e.detailsJson;
    if (raw != null) {
      try {
        details = jsonDecode(raw);
      } on FormatException {
        details = raw;
      }
    }
    if (e.code == WonkyErrorCode.quotaExceeded && details is Map) {
      details = quotaDetails(details);
    }
    return McpToolException(code, e.message, details: details);
  }

  /// (v2) The `details` of `quota_exceeded` (suite 09 §4, Drive 03 §7.1)
  /// from a `QuotaExceededDetails` JSON object: `{needed_bytes,
  /// available_bytes, quota_bytes, charged_user: {id, name}, is_caller,
  /// reason}`.
  static Map<String, Object?> quotaDetails(Map<dynamic, dynamic> d) => {
    'needed_bytes': d['neededBytes'],
    'available_bytes': d['availableBytes'],
    'quota_bytes': d['quotaBytes'],
    'charged_user': {'id': d['chargedUserId'], 'name': d['chargedUserName']},
    'is_caller': d['isCaller'],
    'reason': d['reason'],
  };
}

/// An image returned by a tool (MCP image content).
class ToolImage {
  const ToolImage(this.base64Data, {this.mimeType = 'image/png'});

  final String base64Data;
  final String mimeType;
}

/// The successful result of a tool: machine-readable [structured] content
/// plus a short human [text] summary (suite 09 §7).
class ToolResult {
  const ToolResult(this.structured, {String? text, this.images = const []})
    : _text = text;

  final Object? structured;
  final String? _text;
  final List<ToolImage> images;

  /// The text content: the summary, or the JSON when there is none.
  String get text {
    final t = _text;
    if (t != null) return t;
    return jsonEncode(structured);
  }
}

/// What a tool call produced: a result or a structured error.
class ToolOutcome {
  const ToolOutcome.success(ToolResult this.result) : error = null;
  const ToolOutcome.failure(McpToolException this.error) : result = null;

  final ToolResult? result;
  final McpToolException? error;

  bool get isError => error != null;
}

/// Who calls a tool and with which rights (a personal access token).
class ToolContext {
  ToolContext({
    required this.session,
    required this.actor,
    required this.scopes,
    this.tokenId,
    this.clientName,
    this.groupId,
    this.onBehalfOfSessionId,
    this.changeGuard,
    this.guardDestructive = false,
  });

  final Session session;

  /// The token's user, `actorKind: mcp`.
  final Actor actor;

  /// Scopes granted by the token.
  final Set<String> scopes;

  /// The token row id (rate limits); null in tests that build contexts.
  final int? tokenId;

  /// The MCP client name from `initialize` (`clientInfo.name`), shown in
  /// presence and the control pill.
  String? clientName;

  /// AI assistant runs (Write 09 §5.2): ops of one run share [groupId] and
  /// name the requesting app session in `RemoteOp.onBehalfOfSessionId`, so
  /// that session puts them on its own undo stack as one step.
  String? groupId;
  String? onBehalfOfSessionId;

  /// Checks a content change before it is submitted (the AI destructive
  /// guard); throws a [McpToolException] to refuse it.
  void Function(Delta head, Delta change, String toolName)? changeGuard;

  /// AI runs: destructive spreadsheet operations (Sheets 12 §6.13) fail
  /// with `needs_confirmation` until the user allowed the call (the loop
  /// then retries with this off).
  bool guardDestructive;

  /// Display label of the agent ("Claude Code (MCP)", "Assistant").
  String get agentLabel {
    final name = clientName?.trim() ?? '';
    if (actor.kind == ActorKind.ai) return name.isEmpty ? 'Assistant' : name;
    return name.isEmpty ? 'MCP agent' : '$name (MCP)';
  }

  bool hasAnyScope(Set<String> any) =>
      any.isEmpty || any.any((s) => scopes.contains(s));
}

/// Typed access to validated tool arguments.
class ToolArgs {
  const ToolArgs(this.values);

  final Map<String, Object?> values;

  bool has(String key) => values.containsKey(key) && values[key] != null;

  /// Whether the key is present (even with a null value).
  bool present(String key) => values.containsKey(key);

  String? string(String key) {
    final v = values[key];
    return v is String ? v : null;
  }

  String requireString(String key) =>
      string(key) ??
      (throw McpToolException(McpErrorCode.invalidArgs, '"$key" is required'));

  int? integer(String key) {
    final v = values[key];
    return v is num ? v.toInt() : null;
  }

  num? number(String key) {
    final v = values[key];
    return v is num ? v : null;
  }

  bool? boolean(String key) {
    final v = values[key];
    return v is bool ? v : null;
  }

  Map<String, dynamic>? object(String key) {
    final v = values[key];
    return v is Map ? v.cast<String, dynamic>() : null;
  }

  List<Object?>? list(String key) {
    final v = values[key];
    return v is List ? v.cast<Object?>() : null;
  }

  UuidValue? uuid(String key) {
    final v = string(key);
    if (v == null) return null;
    try {
      return UuidValue.withValidation(v);
    } on FormatException {
      throw McpToolException(McpErrorCode.invalidArgs, '"$key" is not a uuid');
    }
  }

  UuidValue requireUuid(String key) =>
      uuid(key) ??
      (throw McpToolException(McpErrorCode.invalidArgs, '"$key" is required'));

  List<UuidValue> uuids(String key) => [
    for (final v in list(key) ?? const [])
      if (v is String)
        () {
          try {
            return UuidValue.withValidation(v);
          } on FormatException {
            throw McpToolException(
              McpErrorCode.invalidArgs,
              '"$key" contains an invalid uuid',
            );
          }
        }(),
  ];
}

/// The signature of a tool implementation.
typedef ToolHandler = Future<ToolResult> Function(ToolContext ctx, ToolArgs a);
