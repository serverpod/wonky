// Named parameters can't initialize private fields directly.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../platform/publications/publication_api.dart';

/// `/api/pub/v1/**` (specs/18 §7.3): the API blogs call with their
/// publication's API key (`Authorization: Bearer wpk_…`). Runs on an
/// internal session (the bearer token must not reach the app's JWT
/// handler, like `/mcp`); the key is checked from the headers before the
/// body is read.
class PublicationApiRoute extends Route {
  PublicationApiRoute({Serverpod? pod})
    : _pod = pod,
      super(methods: {Method.get, Method.post, Method.delete});

  final Serverpod? _pod;

  static const prefix = '/api/pub/v1/';

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
    final path = request.url.path;
    if (!path.startsWith(prefix)) return _json(PublicationApi.notFound());
    final segments = path
        .substring(prefix.length)
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    final auth = await PublicationApi.authenticate(
      session,
      authorization: request.headers['authorization']?.join(', '),
      declaredLength: request.body.contentLength,
    );
    if (auth.refused case final refused?) return _json(refused);
    String body = '';
    if (request.method == Method.post) {
      try {
        body = await request.readAsString(
          maxLength: PublicationApi.maxBodyBytes,
        );
      } on MaxBodySizeExceeded {
        return _json(
          PublicationApiResult.error(413, 'tooLarge', 'The body is too large.'),
        );
      }
    }
    final result = await PublicationApi.handle(
      session,
      auth.publication!,
      method: request.method.name.toUpperCase(),
      segments: segments,
      query: request.url.queryParameters,
      body: body,
    );
    if (result.stream case final stream?) {
      return Response(
        200,
        headers: Headers.build((h) {
          for (final e in result.headers.entries) {
            h[e.key] = [e.value];
          }
        }),
        body: Body.fromDataStream(
          stream,
          mimeType: _mime(result.contentType),
          contentLength: result.contentLength,
        ),
      );
    }
    return _json(result);
  }

  static MimeType _mime(String? type) {
    try {
      return MimeType.parse(type ?? 'application/octet-stream');
    } on Object {
      return MimeType.octetStream;
    }
  }

  static Response _json(PublicationApiResult r) => Response(
    r.status,
    headers: Headers.build((h) {
      h['cache-control'] = ['no-store'];
      for (final e in r.headers.entries) {
        h[e.key] = [e.value];
      }
    }),
    body: Body.fromString(jsonEncode(r.json ?? {}), mimeType: MimeType.json),
  );
}
