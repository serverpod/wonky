import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../../common/models.dart';
import '../../common/time.dart';
import '../board_config.dart';
import 'board_github.dart';

/// The webhook side of the GitHub App (specs/16 §13.3): signature check,
/// dedupe on the delivery id, and the compact payload the handler reads.
abstract final class GithubWebhook {
  /// The events the App subscribes to.
  static const events = {'pull_request', 'check_run', 'workflow_run'};

  /// Whether [signatureHeader] (`X-Hub-Signature-256: sha256=<hex>`) is
  /// the HMAC-SHA256 of [body] with [secret]; compared in constant time.
  static bool verifySignature({
    required List<int> body,
    required String? signatureHeader,
    required String secret,
  }) {
    if (secret.isEmpty || signatureHeader == null) return false;
    const prefix = 'sha256=';
    final header = signatureHeader.trim();
    if (!header.toLowerCase().startsWith(prefix)) return false;
    final expected = Hmac(sha256, utf8.encode(secret)).convert(body).toString();
    return constantTimeEquals(header.substring(prefix.length), expected);
  }

  /// Compares [a] and [b] without an early exit on the first difference
  /// (lowercase hex digests and claim codes).
  static bool constantTimeEquals(String a, String b) {
    final x = utf8.encode(a.toLowerCase());
    final y = utf8.encode(b.toLowerCase());
    var diff = x.length ^ y.length;
    for (var i = 0; i < y.length; i++) {
      diff |= (i < x.length ? x[i] : 0) ^ y[i];
    }
    return diff == 0;
  }

  /// The fields of [payload] the handler needs, or null when the event is
  /// not handled (other events or repositories, unparsable JSON). Keeps
  /// the stored row small: never the whole payload.
  static Map<String, Object?>? compact(String event, Object? payload) {
    if (!events.contains(event) || payload is! Map) return null;
    final repo = _map(payload['repository'])['full_name'];
    final out = <String, Object?>{
      'event': event,
      'action': payload['action'],
      'repo': repo,
    };
    switch (event) {
      case 'pull_request':
        final pr = _map(payload['pull_request']);
        if (pr['number'] is! int) return null;
        out['pr'] = {
          'number': pr['number'],
          'body': pr['body'] is String ? pr['body'] : '',
          'author': _map(pr['user'])['login'],
          'headSha': _map(pr['head'])['sha'],
          'state': pr['state'],
          'draft': pr['draft'] == true,
          'merged': pr['merged'] == true,
          'mergeCommitSha': pr['merge_commit_sha'],
          'url': pr['html_url'],
        };
      case 'check_run':
        final run = _map(payload['check_run']);
        out['checkRun'] = {
          'name': run['name'],
          'headSha': run['head_sha'],
          'prNumbers': [
            for (final p in (run['pull_requests'] as List?) ?? const [])
              if (p is Map && p['number'] is int) p['number'],
          ],
        };
      case 'workflow_run':
        final run = _map(payload['workflow_run']);
        out['workflowRun'] = {
          'path': run['path'],
          'status': run['status'],
          'conclusion': run['conclusion'],
          'headSha': run['head_sha'],
          'headBranch': run['head_branch'],
        };
    }
    return out;
  }

  static Map<dynamic, dynamic> _map(Object? v) => v is Map ? v : const {};

  /// Stores delivery [deliveryId] with its compact payload. Returns false
  /// for a delivery seen before (replays and GitHub's redeliveries).
  static Future<bool> record(
    Session session, {
    required String deliveryId,
    required String event,
    required Map<String, Object?> payload,
  }) async {
    final existing = await BoardGithubDelivery.db.findFirstRow(
      session,
      where: (t) => t.deliveryId.equals(deliveryId),
    );
    if (existing != null) return false;
    try {
      await BoardGithubDelivery.db.insertRow(
        session,
        BoardGithubDelivery(
          deliveryId: deliveryId,
          event: event,
          receivedAt: nowUtc(),
          payload: jsonEncode(payload),
        ),
      );
      return true;
    } on DatabaseException {
      // A concurrent insert of the same id won the unique index.
      return false;
    }
  }

  /// The largest payload accepted (GitHub caps deliveries at 25 MB; the
  /// events used here are far smaller: tens of KB).
  static const maxBodyBytes = 5 * 1024 * 1024;

  /// The checks that need only the headers (before the body is read, so a
  /// refused request never buffers one): the status when the delivery is
  /// answered without reading it, else null. `202` when the integration
  /// is disabled, `401` without a secret or a `sha256=` signature header,
  /// `400` without the GitHub headers, `413` when the declared size is
  /// over [maxBodyBytes].
  static int? precheck(Session session, Map<String, String> headers) {
    if (!BoardConfig.current.github.enabled) return 202;
    final h = {for (final e in headers.entries) e.key.toLowerCase(): e.value};
    final signature = h['x-hub-signature-256']?.trim().toLowerCase();
    if (signature == null || !signature.startsWith('sha256=')) return 401;
    if (secretSource() == null) {
      session.log(
        'board.github: webhook refused: the password '
        '${BoardGithubConfig.webhookSecretPassword} is not set',
        level: LogLevel.warning,
      );
      return 401;
    }
    final deliveryId = h['x-github-delivery']?.trim();
    if (h['x-github-event'] == null ||
        deliveryId == null ||
        deliveryId.isEmpty ||
        deliveryId.length > 100) {
      return 400;
    }
    final declared = int.tryParse(h['content-length'] ?? '');
    if (declared != null && declared > maxBodyBytes) return 413;
    return null;
  }

  /// The webhook secret (tests replace it).
  static String? Function() secretSource = secret;

  /// Handles a delivery and returns the HTTP status (specs/16 §13.3):
  /// `202` at once (also when the integration is disabled, for events
  /// that are not handled and for duplicates), `401` without a valid
  /// signature, `400` without the GitHub headers. The work runs in
  /// [BoardGithubFutureCall.handle].
  static Future<int> receive(
    Session session, {
    required Map<String, String> headers,
    required List<int> body,
  }) async {
    if (!BoardConfig.current.github.enabled) return 202;
    final key = secretSource();
    if (key == null) {
      session.log(
        'board.github: webhook refused: the password '
        '${BoardGithubConfig.webhookSecretPassword} is not set',
        level: LogLevel.warning,
      );
      return 401;
    }
    final h = {for (final e in headers.entries) e.key.toLowerCase(): e.value};
    if (!verifySignature(
      body: body,
      signatureHeader: h['x-hub-signature-256'],
      secret: key,
    )) {
      return 401;
    }
    final event = h['x-github-event'];
    final deliveryId = h['x-github-delivery']?.trim();
    if (event == null ||
        deliveryId == null ||
        deliveryId.isEmpty ||
        deliveryId.length > 100) {
      return 400;
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(body));
    } on FormatException {
      return 400;
    }
    final payload = compact(event, json);
    if (payload == null) return 202;
    if (!await record(
      session,
      deliveryId: deliveryId,
      event: event,
      payload: payload,
    )) {
      return 202;
    }
    try {
      await BoardGithub.deliveryScheduler(session, deliveryId, Duration.zero);
    } on Object catch (e) {
      session.log(
        'board.github: could not schedule delivery $deliveryId: $e',
        level: LogLevel.error,
      );
    }
    return 202;
  }

  /// The webhook secret password, or null when unset.
  static String? secret() {
    try {
      final s = Serverpod.instance.getPassword(
        BoardGithubConfig.webhookSecretPassword,
      );
      return s == null || s.trim().isEmpty ? null : s.trim();
    } on Object {
      return null;
    }
  }
}
