import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Ids, secrets and webhook signatures of publications (specs/18 §6, §7.1).
///
/// Webhooks are signed per Standard Webhooks
/// (https://www.standardwebhooks.com/): the secret is `whsec_` + base64 of
/// the key bytes, the signature `v1,` + base64 of
/// HMAC-SHA256(key, `<id>.<timestamp>.<body>`).
abstract final class PublicationKeys {
  static Random random = Random.secure();

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static String _token(int length) => List.generate(
    length,
    (_) => _alphabet[random.nextInt(_alphabet.length)],
  ).join();

  /// The public id in contributor links: `pub_` + 22 url-safe characters.
  static String newPublicId() => 'pub_${_token(22)}';

  static final publicIdPattern = RegExp(r'^pub_[A-Za-z0-9_-]{22}$');

  /// A new signing secret: `whsec_` + base64 of 32 random bytes.
  static String newSigningSecret() {
    final bytes = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    return 'whsec_${base64.encode(bytes)}';
  }

  /// A new API key: `wpk_` + 40 url-safe characters.
  static String newApiKey() => 'wpk_${_token(40)}';

  static final apiKeyPattern = RegExp(r'^wpk_[A-Za-z0-9_-]{40}$');

  /// SHA-256 (hex) of an API key, the form it is stored in.
  static String hashApiKey(String key) =>
      sha256.convert(utf8.encode(key)).toString();

  /// The signature of one webhook: `v1,<base64>`.
  static String sign({
    required String secret,
    required String webhookId,
    required int timestamp,
    required String body,
  }) {
    final key = base64.decode(secret.substring('whsec_'.length));
    final mac = Hmac(
      sha256,
      key,
    ).convert(utf8.encode('$webhookId.$timestamp.$body'));
    return 'v1,${base64.encode(mac.bytes)}';
  }

  /// The `webhook-signature` header: one signature per [secrets] (two while
  /// a rotated secret still signs), space separated.
  static String signatureHeader({
    required Iterable<String> secrets,
    required String webhookId,
    required int timestamp,
    required String body,
  }) => [
    for (final s in secrets)
      sign(secret: s, webhookId: webhookId, timestamp: timestamp, body: body),
  ].join(' ');
}
