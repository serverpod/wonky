import 'package:wonky_sheets_script/wonky_sheets_script.dart'
    show FetchFailure, FetchRequestData;

import '../../sheets/scripts/url_fetch_proxy.dart';

/// The answer of a blog's server to an outbound call.
class PublicationHttpResult {
  const PublicationHttpResult(this.status, {this.body = '', this.error});

  /// HTTP status; 0 when the call failed before an answer (network error,
  /// timeout, blocked address).
  final int status;
  final String body;
  final String? error;

  bool get ok => status >= 200 && status < 300;
}

/// Outbound HTTP of publications (specs/18 §7.2, §8.2): webhooks and the
/// `.well-known` verification. Tests replace [instance] with a fake.
abstract class PublicationHttp {
  static PublicationHttp? override;

  static PublicationHttp get instance => override ?? _default;
  static final PublicationHttp _default = SafePublicationHttp();

  Future<PublicationHttpResult> post(
    String url, {
    required Map<String, String> headers,
    required String body,
  });

  Future<PublicationHttpResult> get(String url);
}

/// [PublicationHttp] through the SSRF-safe [UrlFetchProxy] (specs/13 §1):
/// https on port 443 only, public addresses only (pinned), no redirects,
/// 10 s timeout, answers read up to 1 MB.
class SafePublicationHttp implements PublicationHttp {
  SafePublicationHttp({UrlFetchProxy? proxy})
    : _proxy =
          proxy ??
          UrlFetchProxy(
            ports: const {443},
            maxRedirects: 0,
            maxResponseBytes: 1024 * 1024,
            maxPayloadBytes: 6 * 1024 * 1024,
            userAgent: 'WonkyWork-Publications/1.0 (+https://wonky.work)',
          );

  final UrlFetchProxy _proxy;

  static const timeoutSeconds = 10;

  @override
  Future<PublicationHttpResult> post(
    String url, {
    required Map<String, String> headers,
    required String body,
  }) => _send(
    FetchRequestData(
      url: url,
      method: 'post',
      headers: headers,
      payload: body,
      contentType: 'application/json',
      followRedirects: false,
      timeoutSeconds: timeoutSeconds,
    ),
  );

  @override
  Future<PublicationHttpResult> get(String url) => _send(
    FetchRequestData(
      url: url,
      headers: const {'accept': 'application/json'},
      followRedirects: false,
      timeoutSeconds: timeoutSeconds,
    ),
  );

  Future<PublicationHttpResult> _send(FetchRequestData request) async {
    try {
      final res = await _proxy.fetch(request);
      return PublicationHttpResult(res.statusCode, body: res.contentText);
    } on FetchFailure catch (e) {
      return PublicationHttpResult(0, error: e.message);
    }
  }
}
