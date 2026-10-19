@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope;
import 'package:wonky_mcp_stdio/wonky_mcp_stdio.dart';
import 'package:wonky_server/src/platform/mcp/mcp_config.dart';
import 'package:wonky_server/src/platform/mcp/mcp_http.dart';
import 'package:wonky_server/src/platform/mcp/mcp_route.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// A raw JSON-RPC HTTP response.
class _Reply {
  _Reply(this.status, this.headers, this.body);
  final int status;
  final HttpHeaders headers;
  final String body;
  Map<String, dynamic> get json =>
      (jsonDecode(body) as Map).cast<String, dynamic>();
}

void main() {
  withWonkyServerpod('Given the /mcp route on the web server', (
    sessionBuilder,
    endpoints,
  ) {
    late Uri url;
    late McpHttpHandler handler;
    final http = HttpClient();
    setUpAll(() async {
      final pod = sessionBuilder.build().serverpod;
      handler = McpHttpHandler(
        config: McpConfig(
          allowedHosts: {'localhost', '127.0.0.1'},
          allowedOrigins: {'http://localhost:8082'},
        ),
      );
      pod.webServer.addRoute(McpRoute(handler: handler, pod: pod), '/mcp');
      if (!pod.webServer.running) await pod.webServer.start();
      url = Uri.parse('http://localhost:${pod.webServer.port}/mcp');
    });
    tearDownAll(() async {
      await handler.closeAll();
      http.close(force: true);
    });

    Future<_Reply> send(
      String method, {
      Object? body,
      String? token,
      String? sessionId,
      Map<String, String> headers = const {},
    }) async {
      final req = await http.openUrl(method, url);
      req.headers.set('accept', 'application/json, text/event-stream');
      if (token != null) req.headers.set('authorization', 'Bearer $token');
      if (sessionId != null) req.headers.set('mcp-session-id', sessionId);
      headers.forEach(req.headers.set);
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close();
      return _Reply(
        res.statusCode,
        res.headers,
        await res.transform(utf8.decoder).join(),
      );
    }

    Map<String, Object?> rpc(Object id, String method, [Object? params]) => {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': ?params,
    };

    test(
      'when no token is sent then 401 with a bearer challenge is returned',
      () async {
        final r = await send('POST', body: rpc(1, 'tools/list'));

        expect(r.status, 401);
        expect(r.headers.value('www-authenticate'), startsWith('Bearer'));
        expect((r.json['error'] as Map)['code'], -32001);
      },
    );

    test('when a request without a token is over the size cap then it is '
        'refused from its headers (401, not 413: the body is never '
        'read)', () async {
      final req = await http.postUrl(url);
      req.headers.contentType = ContentType.json;
      req.add(List<int>.filled(McpHttpHandler.maxBodyChars + 1, 0x20));
      final res = await req.close();
      await res.drain<void>();

      expect(res.statusCode, 401);
    });

    /// Posts [bytes] bytes; the status, or null when the server closed the
    /// connection before the response arrived. A server that refuses a
    /// request while its body is still arriving may close the connection
    /// with unread bytes, which the client sees as a reset (Linux).
    Future<int?> post(String token, int bytes) async {
      try {
        final req = await http.postUrl(url);
        req.headers
          ..set('authorization', 'Bearer $token')
          ..contentType = ContentType.json;
        req.add(List<int>.filled(bytes, 0x20));
        final res = await req.close();
        await res.drain<void>();
        return res.statusCode;
      } on IOException {
        return null;
      }
    }

    test('when a request with a valid token sends a body over the cap then '
        'it is refused (413, or the connection is closed)', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final h = await McpHarness.forUser(anna);

      final status = await post(h.secret, McpHttpHandler.maxBodyChars + 1);

      expect(status, anyOf(413, isNull));
      // The route keeps serving after the refusal.
      final r = await send('POST', body: rpc(1, 'tools/list'), token: h.secret);
      expect(r.status, 200);
    });

    test('when a request has an invalid token then it is refused with 401 '
        '(checked before the body is read, CQ-13)', () async {
      expect(await post('wkpat_x', 16), 401);
    });

    test('when a revoked token is sent then it is rejected', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final h = await McpHarness.forUser(anna);
      final tokens = await endpoints.accessToken.list(anna.endpointSession);
      await endpoints.accessToken.revoke(anna.endpointSession, tokens.first.id);

      final r = await send('POST', body: rpc(1, 'tools/list'), token: h.secret);

      expect(r.status, 401);
    });

    test('when a foreign origin calls then it is forbidden', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final h = await McpHarness.forUser(anna);

      final r = await send(
        'POST',
        body: rpc(1, 'tools/list'),
        token: h.secret,
        headers: {'origin': 'https://evil.example'},
      );

      expect(r.status, 403);
    });

    test(
      'when initializing, listing and calling tools then the JSON-RPC session works end to end',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final h = await McpHarness.forUser(anna);

        final init = await send(
          'POST',
          token: h.secret,
          body: rpc(1, 'initialize', {
            'protocolVersion': '2025-06-18',
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 'curl', 'version': '1'},
          }),
        );
        final sid = init.headers.value('mcp-session-id');
        final initialized = await send(
          'POST',
          token: h.secret,
          sessionId: sid,
          body: {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
        );
        final list = await send(
          'POST',
          token: h.secret,
          sessionId: sid,
          body: rpc(2, 'tools/list'),
        );
        final created = await send(
          'POST',
          token: h.secret,
          sessionId: sid,
          body: rpc(3, 'tools/call', {
            'name': 'drive.create_document',
            'arguments': {'name': 'Via HTTP', 'markdown': 'Hello'},
          }),
        );
        final item =
            ((created.json['result'] as Map)['structuredContent']
                    as Map)['item']
                as Map;
        final edited = await send(
          'POST',
          token: h.secret,
          sessionId: sid,
          body: rpc(4, 'tools/call', {
            'name': 'write.insert_markdown',
            'arguments': {
              'document_uuid': item['uuid'],
              'markdown': 'World',
              'at': {'type': 'end'},
            },
          }),
        );
        final bad = await send(
          'POST',
          token: h.secret,
          sessionId: sid,
          body: rpc(5, 'tools/call', {
            'name': 'write.insert_markdown',
            'arguments': {'document_uuid': item['uuid']},
          }),
        );

        expect(init.status, 200);
        expect(sid, isNotNull);
        expect(
          (init.json['result'] as Map)['serverInfo'],
          containsPair('name', 'wonky-work'),
        );
        expect(initialized.status, 202);
        final names = [
          for (final t in (list.json['result'] as Map)['tools'] as List)
            (t as Map)['name'],
        ];
        expect(names, containsAll(['drive.search', 'write.get_document']));
        expect(names, contains('drive.create_spreadsheet'));
        expect((edited.json['result'] as Map)['isError'], isNot(true));
        final badResult = bad.json['result'] as Map;
        expect(badResult['isError'], isTrue);
        final payload = jsonDecode(
          ((badResult['content'] as List).first as Map)['text'] as String,
        );
        expect(payload['code'], 'invalid_args');
        final doc = await endpoints.document.getSnapshot(
          anna.endpointSession,
          UuidValue.withValidation(item['document_uuid'] as String),
          null,
        );
        expect(doc.deltaJson, contains('World'));

        final deleted = await send('DELETE', token: h.secret, sessionId: sid);
        final after = await send(
          'POST',
          token: h.secret,
          sessionId: sid,
          body: rpc(6, 'tools/list'),
        );
        expect(deleted.status, 200);
        expect(after.status, 404);
      },
    );

    test(
      'when a session is used with another token then it is forbidden',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final a = await McpHarness.forUser(anna);
        final b = await McpHarness.forUser(anna);
        final init = await send(
          'POST',
          token: a.secret,
          body: rpc(1, 'initialize', {
            'protocolVersion': '2025-06-18',
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 'x', 'version': '1'},
          }),
        );

        final r = await send(
          'POST',
          token: b.secret,
          sessionId: init.headers.value('mcp-session-id'),
          body: rpc(2, 'tools/list'),
        );

        expect(r.status, 403);
      },
    );

    test(
      'when a token lacks ui:control then ui tools are not listed',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final h = await McpHarness.forUser(
          anna,
          scopes: [McpScope.driveRead, McpScope.writeRead],
        );
        final init = await send(
          'POST',
          token: h.secret,
          body: rpc(1, 'initialize', {
            'protocolVersion': '2025-06-18',
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 'x', 'version': '1'},
          }),
        );

        await send(
          'POST',
          token: h.secret,
          sessionId: init.headers.value('mcp-session-id'),
          body: {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
        );
        final list = await send(
          'POST',
          token: h.secret,
          sessionId: init.headers.value('mcp-session-id'),
          body: rpc(2, 'tools/list'),
        );

        expect(list.json['result'], isNotNull, reason: list.body);
        final names = [
          for (final t in (list.json['result'] as Map)['tools'] as List)
            (t as Map)['name'] as String,
        ];
        expect(names.where((n) => n.startsWith('ui.')), isEmpty);
        expect(names, isNot(contains('write.insert_markdown')));
        expect(names, contains('write.get_document'));
      },
    );

    test(
      'when a stdio client goes through wonky_mcp_stdio then the session works',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final h = await McpHarness.forUser(anna);
        final input = StreamController<List<int>>();
        final output = StreamController<List<int>>();
        final lines = output.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .map((l) => (jsonDecode(l) as Map).cast<String, dynamic>())
            .asBroadcastStream();
        final proxy = StdioHttpProxy(
          url: url,
          token: h.secret,
          input: input.stream,
          output: output.sink,
          log: StringBuffer(),
        );
        final done = proxy.run();
        void send(Map<String, Object?> m) =>
            input.add(utf8.encode('${jsonEncode(m)}\n'));

        send(
          rpc(1, 'initialize', {
            'protocolVersion': '2025-06-18',
            'capabilities': <String, Object?>{},
            'clientInfo': {'name': 'stdio-test', 'version': '1'},
          }),
        );
        final init = await lines.firstWhere((m) => m['id'] == 1);
        send({'jsonrpc': '2.0', 'method': 'notifications/initialized'});
        send(
          rpc(2, 'tools/call', {
            'name': 'drive.create_document',
            'arguments': {'name': 'Through stdio'},
          }),
        );
        final created = await lines.firstWhere((m) => m['id'] == 2);
        await input.close();
        final code = await done;

        expect((init['result'] as Map)['protocolVersion'], isA<String>());
        final item =
            ((created['result'] as Map)['structuredContent'] as Map)['item']
                as Map;
        expect(item['name'], 'Through stdio');
        expect(code, 0);
      },
    );

    for (final profile in [mcp.McpProtocol.legacy, mcp.McpProtocol.stable]) {
      test(
        'when the mcp_dart client connects with the ${profile.name} profile then it can read a document',
        () async {
          final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
          final h = await McpHarness.forUser(anna);
          final doc = await TestDrive.document(
            endpoints,
            anna,
            name: 'Client',
            markdown: '# Hi\n\nFrom the client test.',
          );
          final client = mcp.McpClient(
            const mcp.Implementation(name: 'test-client', version: '1.0.0'),
            options: mcp.McpClientOptions(protocol: profile),
          );
          final transport = mcp.StreamableHttpClientTransport(
            url,
            opts: mcp.StreamableHttpClientTransportOptions(
              requestInit: {
                'headers': {'Authorization': 'Bearer ${h.secret}'},
              },
            ),
          );
          await client.connect(transport);

          final tools = await client.listTools();
          final result = await client.callTool(
            mcp.CallToolRequest(
              name: 'write.get_document',
              arguments: {'document_uuid': doc.uuid.uuid},
            ),
          );
          final resources = await client.readResource(
            mcp.ReadResourceRequest(uri: 'wonky://doc/${doc.uuid.uuid}'),
          );
          await client.close();

          expect(
            tools.tools.map((t) => t.name),
            contains('write.get_document'),
          );
          expect(result.isError, isFalse);
          expect(
            (result.content.first as mcp.TextContent).text,
            contains('From the client test.'),
          );
          expect(
            (resources.contents.first as mcp.TextResourceContents).text,
            contains('# Hi'),
          );
        },
      );
    }
  });
}
