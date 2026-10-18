// Named parameters can't initialize private fields directly.
// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import 'mcp_http.dart';

/// `/mcp` on the Serverpod web server (suite 09 §1): adapts Relic requests
/// to [McpHttpHandler] (Streamable HTTP; JSON responses, `GET` event
/// stream for sessions).
///
/// The route runs on an internal session instead of Serverpod's web-call
/// session: the latter would hand the `Authorization: Bearer wkpat_…`
/// header to the app's JWT authentication handler. MCP authenticates with
/// personal access tokens only (and ignores the auth cookie, suite 13).
class McpRoute extends Route {
  McpRoute({McpHttpHandler? handler, Serverpod? pod})
    : handler = handler ?? McpHttpHandler(),
      _pod = pod,
      super(methods: {Method.get, Method.post, Method.delete, Method.options});

  final McpHttpHandler handler;
  final Serverpod? _pod;

  @override
  Future<Result> call(Request req) async {
    final session = await (_pod ?? Serverpod.instance).createSession(
      enableLogging: false,
    );
    try {
      return await handleCall(session, req);
    } finally {
      await session.close();
    }
  }

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final headers = <String, String>{
      for (final e in request.headers.entries) e.key: e.value.join(', '),
    };
    final method = request.method.name.toUpperCase();
    // Header checks and the token first: a refused request never buffers
    // its body (CQ-13).
    final refused = await handler.preauthenticate(
      session,
      McpHttpRequest(method: method, headers: headers),
    );
    if (refused != null) return _response(refused);
    String body = '';
    if (request.method == Method.post) {
      try {
        body = await request.readAsString(
          maxLength: McpHttpHandler.maxBodyChars,
        );
      } on MaxBodySizeExceeded {
        return Response(
          413,
          body: Body.fromString(
            'Request too large',
            mimeType: MimeType.plainText,
          ),
        );
      }
    }
    final r = await handler.handle(
      session,
      McpHttpRequest(method: method, headers: headers, body: body),
    );
    return _response(r);
  }

  static Response _response(McpHttpResponse r) {
    final responseHeaders = Headers.build((h) {
      for (final e in r.headers.entries) {
        h[e.key] = [e.value];
      }
    });
    final type = r.contentType == null ? null : MimeType.parse(r.contentType!);
    final Body responseBody;
    if (r.stream != null) {
      responseBody = Body.fromDataStream(
        r.stream!.map(Uint8List.fromList),
        mimeType: type,
      );
    } else if (r.body != null) {
      responseBody = Body.fromString(r.body!, mimeType: type);
    } else {
      responseBody = Body.empty();
    }
    return Response(r.status, headers: responseHeaders, body: responseBody);
  }
}
