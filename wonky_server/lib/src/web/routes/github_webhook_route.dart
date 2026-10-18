import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../../platform/board/github/github_webhook.dart';

/// `POST /api/github/webhook` (specs/16 §13.3): the webhooks of the
/// board's GitHub App. Checks the signature, stores the delivery once and
/// answers `202`; the work runs in a future call.
class GithubWebhookRoute extends Route {
  GithubWebhookRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final headers = {
      for (final e in request.headers.entries) e.key: e.value.join(', '),
    };
    // Disabled, unsigned or incomplete deliveries are answered from the
    // headers alone, without reading the body.
    final refused = GithubWebhook.precheck(session, headers);
    if (refused != null) return _status(refused);
    final Uint8List body;
    try {
      final builder = BytesBuilder(copy: false);
      await request
          .read(maxLength: GithubWebhook.maxBodyBytes)
          .forEach(builder.add);
      body = builder.takeBytes();
    } on MaxBodySizeExceeded {
      return _status(413);
    }
    final status = await GithubWebhook.receive(
      session,
      headers: headers,
      body: body,
    );
    return _status(status);
  }

  static Response _status(int status) => Response(
    status,
    body: Body.fromString(switch (status) {
      202 => 'Accepted',
      400 => 'Bad request',
      401 => 'Unauthorized',
      413 => 'Payload too large',
      _ => 'Error',
    }, mimeType: MimeType.plainText),
  );
}
