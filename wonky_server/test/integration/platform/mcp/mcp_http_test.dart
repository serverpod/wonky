@Tags(['integration'])
library;

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/rate_limiter.dart';
import 'package:wonky_server/src/platform/mcp/mcp_config.dart';
import 'package:wonky_server/src/platform/mcp/mcp_http.dart';
import 'package:wonky_server/src/platform/mcp/mcp_session_directory.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// Two `/mcp` handlers sharing one session directory stand for two server
/// instances behind a load balancer (specs/13 §4).
void main() {
  withWonkyServerpod('Given MCP sessions on two instances', (
    sessionBuilder,
    endpoints,
  ) {
    late McpHttpHandler first;
    late McpHttpHandler second;
    late TestUser anna;
    late McpHarness token;
    setUp(() async {
      final directory = InMemoryMcpSessionDirectory();
      McpHttpHandler instance() => McpHttpHandler(
        config: McpConfig(allowedHosts: {'localhost'}),
        directory: directory,
      );
      first = instance();
      second = instance();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      token = await McpHarness.forUser(anna);
    });
    tearDown(() async {
      await first.closeAll();
      await second.closeAll();
    });

    Future<McpHttpResponse> send(
      McpHttpHandler handler,
      String method, {
      Object? body,
      String? sessionId,
      String? secret,
    }) => handler.handle(
      anna.session,
      McpHttpRequest(
        method: method,
        headers: {
          'host': 'localhost',
          'accept': 'application/json, text/event-stream',
          'authorization': 'Bearer ${secret ?? token.secret}',
          'mcp-session-id': ?sessionId,
        },
        body: body == null ? '' : jsonEncode(body),
      ),
    );

    Map<String, Object?> rpc(Object id, String method, [Object? params]) => {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': ?params,
    };

    Future<String> initialize(McpHttpHandler handler) async {
      final r = await send(
        handler,
        'POST',
        body: rpc(1, 'initialize', {
          'protocolVersion': '2025-06-18',
          'capabilities': <String, Object?>{},
          'clientInfo': {'name': 'Agent', 'version': '1'},
        }),
      );
      return r.headers['mcp-session-id']!;
    }

    test(
      'when a session continues on the other instance then it is resumed',
      () async {
        final sid = await initialize(first);

        // Even the client's `initialized` may land on the other instance.
        final initialized = await send(
          second,
          'POST',
          sessionId: sid,
          body: {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
        );
        final r = await send(
          first,
          'POST',
          sessionId: sid,
          body: rpc(2, 'tools/list'),
        );
        final resumed = await send(
          second,
          'POST',
          sessionId: sid,
          body: rpc(3, 'tools/list'),
        );

        expect(initialized.status, 202);
        expect(resumed.status, 200);
        expect((jsonDecode(resumed.body!) as Map)['error'], isNull);
        expect(r.status, 200);
        final result = (jsonDecode(r.body!) as Map)['result'] as Map;
        expect(result['tools'], isNotEmpty);
        expect(second.sessions.map((s) => s.id), [sid]);
      },
    );

    test(
      'when the session is deleted on one instance then the other one '
      'refuses it',
      () async {
        final sid = await initialize(first);

        final deleted = await send(second, 'DELETE', sessionId: sid);
        final after = await send(
          first,
          'POST',
          sessionId: sid,
          body: rpc(2, 'tools/list'),
        );

        expect(deleted.status, 200);
        expect(after.status, 404);
        expect(first.sessions, isEmpty);
      },
    );

    test(
      'when another token resumes the session elsewhere then it is forbidden',
      () async {
        final sid = await initialize(first);
        final other = await McpHarness.forUser(anna);

        final r = await send(
          second,
          'POST',
          sessionId: sid,
          secret: other.secret,
          body: rpc(2, 'tools/list'),
        );

        expect(r.status, 403);
        expect(second.sessions, isEmpty);
      },
    );
  });

  withWonkyServerpod('Given the per-token MCP rate limit', (
    sessionBuilder,
    endpoints,
  ) {
    late McpHttpHandler handler;
    late TestUser anna;
    late McpHarness token;
    setUp(() async {
      handler = McpHttpHandler(
        config: McpConfig(allowedHosts: {'localhost'}),
        rateLimiter: RateLimiter(
          name: 'mcp-test-${clock.now().microsecondsSinceEpoch}',
          limit: 1,
        ),
      );
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      token = await McpHarness.forUser(anna);
    });
    tearDown(() => handler.closeAll());

    Future<McpHttpResponse> post(Map<String, Object?> body) => handler.handle(
      anna.session,
      McpHttpRequest(
        method: 'POST',
        headers: {
          'host': 'localhost',
          'accept': 'application/json, text/event-stream',
          'authorization': 'Bearer ${token.secret}',
        },
        body: jsonEncode(body),
      ),
    );

    Map<String, Object?> read(int id) => {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'resources/read',
      'params': {'uri': 'wonky://drive/storage'},
    };

    test('when resources are read over the limit then the request is '
        'refused with 429', () async {
      final first = await post(read(1));

      final second = await post(read(2));

      expect(first.status, isNot(429));
      expect(second.status, 429);
      expect(second.headers['retry-after'], isNotNull);
      expect(
        ((jsonDecode(second.body!) as Map)['error'] as Map)['message'],
        startsWith('Too many requests'),
      );
    });

    test('when a request has no bearer token then the precheck refuses it '
        'from the headers alone', () {
      final r = handler.precheck(
        McpHttpRequest(method: 'POST', headers: {'host': 'localhost'}),
      );

      expect(r?.status, 401);
    });
  });
}
