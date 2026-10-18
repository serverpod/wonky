// Named parameters can't initialize private fields directly.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:serverpod/serverpod.dart';

import '../common/rate_limiter.dart';
import '../users/account_service.dart';
import 'mcp_config.dart';
import 'mcp_session_directory.dart';
import 'tool_support.dart';
import 'wonky_mcp_server.dart';

/// A framework-neutral HTTP request to `/mcp` (built by [McpRoute]).
class McpHttpRequest {
  McpHttpRequest({
    required this.method,
    required Map<String, String> headers,
    this.body = '',
  }) : headers = {
         for (final e in headers.entries) e.key.toLowerCase(): e.value,
       };

  /// `POST`, `GET`, `DELETE` or `OPTIONS`.
  final String method;

  /// Lower-cased header names.
  final Map<String, String> headers;
  final String body;

  String? header(String name) => headers[name.toLowerCase()];
}

/// A framework-neutral HTTP response.
class McpHttpResponse {
  McpHttpResponse(
    this.status, {
    this.headers = const {},
    this.body,
    this.stream,
    this.contentType,
  });

  final int status;
  final Map<String, String> headers;
  final String? body;

  /// Server-sent events (`text/event-stream`).
  final Stream<List<int>>? stream;
  final String? contentType;

  /// A JSON-RPC error response.
  factory McpHttpResponse.rpcError(
    int status,
    int code,
    String message, {
    Object? id,
    Map<String, String> headers = const {},
  }) => McpHttpResponse(
    status,
    headers: headers,
    contentType: 'application/json',
    body: jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    }),
  );
}

/// The `mcp_dart` transport of one connection: JSON-RPC messages posted to
/// `/mcp` are delivered to the protocol layer; responses are routed back to
/// the HTTP exchange that carried the request (by JSON-RPC id), other
/// server messages (notifications) go to the session's `GET` event stream.
///
/// This is the "custom Transport behind a Relic route" design of suite 09
/// §1: `mcp_dart`'s own `StreamableHTTPServerTransport` needs a `dart:io`
/// `HttpRequest`, which Serverpod's Relic web server does not expose.
class McpExchangeTransport implements mcp.Transport {
  McpExchangeTransport({this.sessionId});

  @override
  final String? sessionId;

  @override
  void Function()? onclose;

  @override
  void Function(Error error)? onerror;

  @override
  void Function(mcp.JsonRpcMessage message)? onmessage;

  final Map<String, Completer<Map<String, dynamic>>> _waiting = {};

  /// The tool context of each in-flight request (by JSON-RPC id).
  final Map<String, ToolContext> contexts = {};

  StreamController<List<int>>? _events;
  Timer? _keepAlive;
  bool _closed = false;

  static String keyOf(Object? id) => jsonEncode(id);

  /// The context of the request [extra] belongs to.
  ToolContext contextFor(mcp.RequestHandlerExtra extra) =>
      contexts[keyOf(extra.requestId)] ??
      (throw StateError('No context for request ${extra.requestId}'));

  @override
  Future<void> start() async {}

  /// Delivers one decoded message; for requests waits for the response.
  Future<Map<String, dynamic>?> deliver(
    Map<String, dynamic> json,
    ToolContext ctx, {
    Duration timeout = const Duration(minutes: 10),
  }) async {
    final message = mcp.JsonRpcMessage.fromJson(json);
    final id = json['id'];
    final isRequest = json.containsKey('method') && id != null;
    if (!isRequest) {
      onmessage?.call(message);
      return null;
    }
    final key = keyOf(id);
    if (_waiting.containsKey(key)) {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {
          'code': mcp.ErrorCode.invalidRequest.value,
          'message': 'A request with this id is already in progress.',
        },
      };
    }
    final waiter = Completer<Map<String, dynamic>>();
    _waiting[key] = waiter;
    contexts[key] = ctx;
    try {
      onmessage?.call(message);
      return await waiter.future.timeout(timeout);
    } on TimeoutException {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {
          'code': mcp.ErrorCode.internalError.value,
          'message': 'The request timed out.',
        },
      };
    } finally {
      _waiting.remove(key);
      contexts.remove(key);
    }
  }

  @override
  Future<void> send(mcp.JsonRpcMessage message, {int? relatedRequestId}) async {
    final json = message.toJson();
    final isResponse =
        json.containsKey('id') &&
        !json.containsKey('method') &&
        (json.containsKey('result') || json.containsKey('error'));
    if (isResponse) {
      final waiter = _waiting[keyOf(json['id'])];
      if (waiter != null && !waiter.isCompleted) waiter.complete(json);
      return;
    }
    // Request-related notifications (progress, logging) are dropped: the
    // POST answers with one JSON response. Others go to the event stream.
    if (relatedRequestId != null) return;
    final events = _events;
    if (events != null && !events.isClosed) {
      events.add(utf8.encode('event: message\ndata: ${jsonEncode(json)}\n\n'));
    }
  }

  /// Opens the standalone `GET` event stream (replaces an older one).
  Stream<List<int>> openEvents() {
    unawaited(_events?.close());
    _keepAlive?.cancel();
    final events = StreamController<List<int>>();
    _events = events;
    events.add(utf8.encode(': connected\n\n'));
    _keepAlive = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!events.isClosed) events.add(utf8.encode(': keep-alive\n\n'));
    });
    events.onCancel = () {
      _keepAlive?.cancel();
      if (_events == events) _events = null;
    };
    return events.stream;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _keepAlive?.cancel();
    await _events?.close();
    for (final w in _waiting.values) {
      if (!w.isCompleted) {
        w.completeError(StateError('The MCP session was closed.'));
      }
    }
    onclose?.call();
  }
}

/// A legacy (initialize-era) MCP session (`Mcp-Session-Id`).
class McpSession {
  McpSession({
    required this.id,
    required this.tokenId,
    required this.userId,
    required this.transport,
    required this.server,
    this.clientName,
  }) : lastUsed = clock.now(),
       publishedAt = clock.now();

  final String id;
  final int tokenId;
  final int userId;
  final McpExchangeTransport transport;
  final mcp.McpServer server;
  String? clientName;
  DateTime lastUsed;

  /// When the [McpSessionDirectory] entry was last refreshed.
  DateTime publishedAt;

  /// The client's `initialize` parameters (replayed when resuming).
  Map<String, Object?>? initializeParams;

  McpSessionRecord get record => McpSessionRecord(
    tokenId: tokenId,
    userId: userId,
    clientName: clientName,
    initializeParams: initializeParams,
  );
}

/// The Streamable HTTP endpoint logic of `/mcp` (suite 09 §1–2): host and
/// origin checks, bearer personal-access-token auth, the stateless MCP
/// 2026-07-28 profile (one server per request) and initialize-era sessions
/// keyed by `Mcp-Session-Id`, JSON responses and a `GET` event stream.
///
/// With several instances (specs/13 §4) sessions are registered in the
/// [McpSessionDirectory] (Redis), so any instance can serve them: an
/// instance that does not know a session resumes it from its record, and a
/// session deleted or expired in the directory is gone everywhere.
class McpHttpHandler {
  McpHttpHandler({
    McpConfig? config,
    McpSessionDirectory? directory,
    RateLimiter? rateLimiter,
  }) : _config = config,
       _directory = directory,
       _rateLimiter = rateLimiter;

  final McpConfig? _config;
  McpConfig get config => _config ?? McpConfig.current;

  final RateLimiter? _rateLimiter;

  /// The per-token limit (suite 09 §2): shared with `tools/call` (the
  /// executor's limiter), so reads count against the same budget.
  RateLimiter get rateLimiter =>
      _rateLimiter ?? WonkyMcpServer.executor.rateLimiter;

  /// Requests that do work per call (database reads, file content) and
  /// are rate-limited per token here; `tools/call` is limited by the
  /// executor.
  static const rateLimitedMethods = {
    mcp.Method.resourcesRead,
    mcp.Method.resourcesList,
    mcp.Method.promptsGet,
  };

  final McpSessionDirectory? _directory;
  RedisMcpSessionDirectory? _redisDirectory;

  /// The cluster-wide session registry: the injected one, else Redis when
  /// enabled, else none (a single instance keeps sessions in memory only).
  McpSessionDirectory? get directory {
    if (_directory != null) return _directory;
    final redis = Serverpod.instance.redisController;
    if (redis == null) return null;
    if (_redisDirectory?.redis != redis) {
      _redisDirectory = RedisMcpSessionDirectory(redis);
    }
    return _redisDirectory;
  }

  /// How often a used session refreshes its directory entry.
  static const publishEvery = Duration(minutes: 1);

  final Map<String, McpSession> _sessions = {};
  Timer? _sweeper;

  static const maxSessionsPerUser = 20;

  /// The largest request body: a 10 MB inline upload (`drive.upload_file`)
  /// as base64 plus the JSON-RPC envelope. Checked before the body is read
  /// (declared size) and while reading it.
  static const maxBodyChars = 16 * 1024 * 1024;

  /// Live sessions (tests, diagnostics).
  Iterable<McpSession> get sessions => _sessions.values;

  Map<String, String> _cors(McpHttpRequest r) {
    final origin = r.header('origin');
    if (origin == null || !config.originAllowed(origin)) return const {};
    return {
      'access-control-allow-origin': origin,
      'access-control-allow-credentials': 'false',
      'access-control-expose-headers': 'mcp-session-id, mcp-protocol-version',
      'vary': 'Origin',
    };
  }

  static final _bearer = RegExp(r'^Bearer\s+(\S+)$', caseSensitive: false);

  /// The checks that need only the headers of [r] (enabled, host, origin,
  /// the bearer header's format, a declared body size): the answer when
  /// [r] is refused, else null. [McpRoute] runs them before it reads the
  /// body, so refused requests never buffer one.
  McpHttpResponse? precheck(McpHttpRequest r) {
    if (!config.enabled) {
      return McpHttpResponse.rpcError(404, -32000, 'MCP is disabled.');
    }
    if (!config.hostAllowed(r.header('host'))) {
      return McpHttpResponse(
        403,
        contentType: 'text/plain',
        body: 'Forbidden: host not allowed',
      );
    }
    if (!config.originAllowed(r.header('origin'))) {
      return McpHttpResponse(
        403,
        contentType: 'text/plain',
        body: 'Forbidden: origin not allowed',
      );
    }
    if (r.method == 'OPTIONS') return null;
    if (!_bearer.hasMatch((r.header('authorization') ?? '').trim())) {
      return _missingToken(_cors(r));
    }
    final declared = int.tryParse(r.header('content-length') ?? '');
    if (declared != null && declared > maxBodyChars) {
      return McpHttpResponse.rpcError(413, -32600, 'Request too large.');
    }
    return null;
  }

  static McpHttpResponse _missingToken(Map<String, String> cors) =>
      McpHttpResponse.rpcError(
        401,
        -32001,
        'Missing bearer token. Create a personal access token in '
        'Settings › Developer and send "Authorization: Bearer '
        'wkpat_…".',
        headers: {
          ...cors,
          'www-authenticate': 'Bearer realm="wonky", error="invalid_token"',
        },
      );

  /// [precheck] plus the token itself (CQ-13): the route calls this before
  /// it reads a request body, so an unauthenticated caller can't make the
  /// server buffer up to [maxBodyChars]. Returns the refusal, or null.
  Future<McpHttpResponse?> preauthenticate(
    Session session,
    McpHttpRequest r,
  ) async {
    final refused = precheck(r);
    if (refused != null || r.method == 'OPTIONS' || r.method == 'GET') {
      return refused;
    }
    final match = _bearer.firstMatch((r.header('authorization') ?? '').trim());
    if (match == null) return _missingToken(_cors(r));
    final resolved = await AccountService.authenticate(
      session,
      match.group(1)!,
    );
    if (resolved != null) return null;
    return McpHttpResponse.rpcError(
      401,
      -32001,
      'Invalid, expired or revoked access token.',
      headers: {
        ..._cors(r),
        'www-authenticate': 'Bearer realm="wonky", error="invalid_token"',
      },
    );
  }

  Future<McpHttpResponse> handle(Session session, McpHttpRequest r) async {
    final refused = precheck(r);
    if (refused != null) return refused;
    final cors = _cors(r);
    if (r.method == 'OPTIONS') {
      return McpHttpResponse(
        204,
        headers: {
          ...cors,
          'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
          'access-control-allow-headers':
              'authorization, content-type, accept, mcp-session-id, '
              'mcp-protocol-version, mcp-method, last-event-id',
          'access-control-max-age': '86400',
        },
      );
    }

    // Bearer auth only: the web apps' auth cookie is ignored here (CSRF).
    final auth = r.header('authorization') ?? '';
    final match = _bearer.firstMatch(auth.trim());
    if (match == null) return _missingToken(cors);
    final resolved = await AccountService.authenticate(
      session,
      match.group(1)!,
    );
    if (resolved == null) {
      return McpHttpResponse.rpcError(
        401,
        -32001,
        'Invalid, expired or revoked access token.',
        headers: {
          ...cors,
          'www-authenticate': 'Bearer realm="wonky", error="invalid_token"',
        },
      );
    }
    final (token, actor) = resolved;
    ToolContext context(String? clientName) => ToolContext(
      session: session,
      actor: actor,
      scopes: token.scopes.toSet(),
      tokenId: token.id,
      clientName: clientName,
    );

    _ensureSweeper();
    final sessionId = r.header('mcp-session-id');
    McpSession? mcpSession;
    if (sessionId != null) {
      mcpSession = _sessions[sessionId];
      final dir = directory;
      if (dir != null) {
        McpSessionRecord? record;
        var reachable = true;
        try {
          record = await dir.get(sessionId);
        } on Object catch (e) {
          // Without the directory, trust what this instance knows.
          reachable = false;
          session.log(
            'MCP session directory unavailable: $e',
            level: LogLevel.warning,
          );
        }
        if (reachable && record == null && mcpSession != null) {
          // Deleted or expired on another instance.
          await _close(mcpSession);
          mcpSession = null;
        } else if (record != null && mcpSession == null) {
          if (record.userId != actor.userId || record.tokenId != token.id) {
            return McpHttpResponse.rpcError(
              403,
              -32001,
              'This session belongs to another access token.',
              headers: cors,
            );
          }
          mcpSession = await _open(
            sessionId,
            record,
            scopes: token.scopes.toSet(),
            resumeContext: context(record.clientName),
          );
        }
      }
      if (mcpSession == null) {
        return McpHttpResponse.rpcError(
          404,
          -32001,
          'Session not found or expired. Initialize a new session.',
          headers: cors,
        );
      }
      if (mcpSession.userId != actor.userId || mcpSession.tokenId != token.id) {
        return McpHttpResponse.rpcError(
          403,
          -32001,
          'This session belongs to another access token.',
          headers: cors,
        );
      }
      final now = clock.now();
      mcpSession.lastUsed = now;
      if (dir != null &&
          now.difference(mcpSession.publishedAt) >= publishEvery) {
        mcpSession.publishedAt = now;
        await _publish(session, mcpSession);
      }
    }

    switch (r.method) {
      case 'DELETE':
        if (mcpSession == null) {
          return McpHttpResponse.rpcError(
            400,
            -32600,
            'Missing Mcp-Session-Id.',
            headers: cors,
          );
        }
        await _close(mcpSession);
        try {
          await directory?.remove(mcpSession.id);
        } on Object catch (e) {
          session.log(
            'MCP session directory unavailable: $e',
            level: LogLevel.warning,
          );
        }
        return McpHttpResponse(200, headers: cors);
      case 'GET':
        if (mcpSession == null) {
          return McpHttpResponse(
            405,
            headers: {...cors, 'allow': 'POST, DELETE, OPTIONS'},
            contentType: 'text/plain',
            body: 'Open a session first (initialize) to receive events.',
          );
        }
        return McpHttpResponse(
          200,
          headers: {
            ...cors,
            'cache-control': 'no-cache',
            'mcp-session-id': mcpSession.id,
          },
          contentType: 'text/event-stream',
          stream: mcpSession.transport.openEvents(),
        );
      case 'POST':
        break;
      default:
        return McpHttpResponse(
          405,
          headers: {...cors, 'allow': 'GET, POST, DELETE'},
        );
    }

    if (r.body.length > maxBodyChars) {
      return McpHttpResponse.rpcError(413, -32600, 'Request too large.');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(r.body);
    } on FormatException {
      return McpHttpResponse.rpcError(
        400,
        mcp.ErrorCode.parseError.value,
        'Parse error',
        headers: cors,
      );
    }
    if (decoded is List) {
      return McpHttpResponse.rpcError(
        400,
        mcp.ErrorCode.invalidRequest.value,
        'JSON-RPC batches are not supported.',
        headers: cors,
      );
    }
    if (decoded is! Map) {
      return McpHttpResponse.rpcError(
        400,
        mcp.ErrorCode.invalidRequest.value,
        'Invalid Request',
        headers: cors,
      );
    }
    final json = decoded.cast<String, dynamic>();
    final method = json['method'];
    final id = json['id'];
    if (json['jsonrpc'] != '2.0') {
      return McpHttpResponse.rpcError(
        400,
        mcp.ErrorCode.invalidRequest.value,
        'Invalid Request: jsonrpc must be "2.0".',
        id: id,
        headers: cors,
      );
    }
    if (rateLimitedMethods.contains(method)) {
      final retry = await rateLimiter.check(
        token.id ?? 'user:${actor.userId}',
      );
      if (retry != null) {
        return McpHttpResponse.rpcError(
          429,
          -32000,
          'Too many requests; retry in ${retry.inSeconds + 1} s.',
          id: id,
          headers: {...cors, 'retry-after': '${retry.inSeconds + 1}'},
        );
      }
    }
    if (method == 'subscriptions/listen') {
      return _json(
        {
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': mcp.ErrorCode.methodNotFound.value,
            'message': 'Subscriptions are not supported by this server.',
          },
        },
        cors,
        accept: r.header('accept'),
      );
    }

    var extraHeaders = <String, String>{...cors};
    McpExchangeTransport transport;
    String? clientName = mcpSession?.clientName;
    var stateless = false;
    var created = false;
    if (mcpSession != null) {
      transport = mcpSession.transport;
    } else if (method == mcp.Method.initialize) {
      final userSessions = _sessions.values
          .where((s) => s.userId == actor.userId)
          .toList();
      if (userSessions.length >= maxSessionsPerUser) {
        userSessions.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
        await _close(userSessions.first);
      }
      final params = json['params'];
      clientName = params is Map && params['clientInfo'] is Map
          ? '${params['clientInfo']['name'] ?? ''}'
          : null;
      final newId = const Uuid().v4();
      final s = await _open(
        newId,
        McpSessionRecord(
          tokenId: token.id!,
          userId: actor.userId,
          clientName: clientName,
          initializeParams: params is Map
              ? params.cast<String, Object?>()
              : null,
        ),
        scopes: token.scopes.toSet(),
      );
      if (directory != null) await _publish(session, s);
      transport = s.transport;
      created = true;
      extraHeaders['mcp-session-id'] = newId;
      mcpSession = s;
    } else {
      // Stateless MCP 2026-07-28: one server per request.
      stateless = true;
      final meta = json['params'] is Map ? json['params']['_meta'] : null;
      final info = meta is Map
          ? meta['io.modelcontextprotocol/clientInfo']
          : null;
      clientName = info is Map ? '${info['name'] ?? ''}' : null;
      transport = McpExchangeTransport();
      final server = WonkyMcpServer.create(
        scopes: token.scopes.toSet(),
        contextOf: transport.contextFor,
      );
      await server.connect(transport);
    }
    try {
      Map<String, dynamic>? response;
      try {
        response = await transport.deliver(json, context(clientName));
        // With several instances the client's `notifications/initialized`
        // may land elsewhere: every instance marks the session ready itself
        // (the client's own notification is then a harmless duplicate).
        if (created && directory != null && response?['error'] == null) {
          await _markReady(transport, context(clientName));
        }
      } on FormatException catch (e) {
        return McpHttpResponse.rpcError(
          400,
          mcp.ErrorCode.invalidRequest.value,
          'Invalid Request: ${e.message}',
          id: id,
          headers: extraHeaders,
        );
      } on StateError {
        return McpHttpResponse.rpcError(
          404,
          -32001,
          'The session was closed.',
          id: id,
          headers: extraHeaders,
        );
      }
      if (response == null) return McpHttpResponse(202, headers: extraHeaders);
      return _json(response, extraHeaders, accept: r.header('accept'));
    } finally {
      if (stateless) await transport.close();
    }
  }

  McpHttpResponse _json(
    Map<String, dynamic> json,
    Map<String, String> headers, {
    String? accept,
  }) {
    final body = jsonEncode(json);
    final wantsSse =
        accept != null &&
        accept.contains('text/event-stream') &&
        !accept.contains('application/json') &&
        !accept.contains('*/*');
    if (wantsSse) {
      return McpHttpResponse(
        200,
        headers: {...headers, 'cache-control': 'no-cache'},
        contentType: 'text/event-stream',
        stream: Stream.value(utf8.encode('event: message\ndata: $body\n\n')),
      );
    }
    return McpHttpResponse(
      200,
      headers: headers,
      contentType: 'application/json',
      body: body,
    );
  }

  /// Creates the local state of session [id] (new or resumed).
  ///
  /// A resumed session replays the client's `initialize` (with
  /// [resumeContext]), so the protocol layer is in the same state as on the
  /// instance that created it.
  Future<McpSession> _open(
    String id,
    McpSessionRecord record, {
    required Set<String> scopes,
    ToolContext? resumeContext,
  }) async {
    final transport = McpExchangeTransport(sessionId: id);
    final server = WonkyMcpServer.create(
      scopes: scopes,
      contextOf: transport.contextFor,
    );
    await server.connect(transport);
    if (resumeContext != null) {
      await transport.deliver({
        'jsonrpc': '2.0',
        'id': '_wonky_resume',
        'method': mcp.Method.initialize,
        'params': record.initializeParams ?? const <String, Object?>{},
      }, resumeContext);
      await _markReady(transport, resumeContext);
    }
    final s = McpSession(
      id: id,
      tokenId: record.tokenId,
      userId: record.userId,
      transport: transport,
      server: server,
      clientName: record.clientName,
    )..initializeParams = record.initializeParams;
    _sessions[id] = s;
    transport.onclose = () {
      if (identical(_sessions[id], s)) _sessions.remove(id);
    };
    return s;
  }

  /// Delivers `notifications/initialized` for an initialized session.
  static Future<void> _markReady(
    McpExchangeTransport transport,
    ToolContext context,
  ) async {
    // The protocol marks the session initialized after sending the
    // initialize response; let that settle first.
    await Future<void>.delayed(Duration.zero);
    await transport.deliver({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
    }, context);
  }

  Future<void> _publish(Session session, McpSession s) async {
    try {
      await directory?.put(s.id, s.record, config.sessionIdle);
    } on Object catch (e) {
      session.log(
        'MCP session directory unavailable: $e',
        level: LogLevel.warning,
      );
    }
  }

  Future<void> _close(McpSession s) async {
    if (identical(_sessions[s.id], s)) _sessions.remove(s.id);
    await s.transport.close();
  }

  void _ensureSweeper() {
    _sweeper ??= Timer.periodic(const Duration(minutes: 5), (_) {
      final now = clock.now();
      for (final s in _sessions.values.toList()) {
        if (now.difference(s.lastUsed) > config.sessionIdle) {
          unawaited(_close(s));
        }
      }
    });
  }

  /// Closes every session (tests, shutdown).
  Future<void> closeAll() async {
    _sweeper?.cancel();
    _sweeper = null;
    for (final s in _sessions.values.toList()) {
      await _close(s);
    }
  }
}
