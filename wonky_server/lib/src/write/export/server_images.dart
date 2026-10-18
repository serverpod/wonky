import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/rate_limiter.dart';
import '../../platform/files/file_service.dart';

/// SSRF-safe fetching of remote images (Write 07 §4.4): https only on the
/// default port, public addresses only, no redirects, 10 s, ≤ 10 MB, image
/// content types (no SVG).
abstract final class SafeImageFetcher {
  static const maxBytes = 10 * 1024 * 1024;
  static const timeout = Duration(seconds: 10);

  /// Remote fetches per user and minute through the image proxies (cache
  /// misses only, CQ-14).
  static const fetchesPerMinute = 60;

  static final limiter = RateLimiter(
    name: 'image-proxy',
    limit: fetchesPerMinute,
  );

  /// Counts a remote fetch for [userId]; throws when over the limit.
  static Future<void> checkLimit(int userId) async {
    final retry = await limiter.check('user:$userId');
    if (retry != null) {
      throw Errors.limit('Too many images loaded at once. Try again shortly.');
    }
  }

  /// Fetches [src]; throws a `WonkyException` when it is not allowed or
  /// fails.
  static Future<Uint8List> fetch(String src) async {
    final uri = Uri.tryParse(src);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw Errors.invalid('Only https images can be fetched.');
    }
    if (uri.hasPort && uri.port != 443) {
      throw Errors.invalid('Only the default https port is allowed.');
    }
    final List<InternetAddress> addresses;
    try {
      addresses = await InternetAddress.lookup(uri.host).timeout(timeout);
    } on Object {
      throw Errors.unavailable('The image host could not be resolved.');
    }
    if (addresses.isEmpty || addresses.any(isPrivate)) {
      throw Errors.forbidden('This address cannot be fetched.');
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        throw Errors.notFound('Image');
      }
      final type = response.headers.contentType?.mimeType ?? '';
      if (!type.startsWith('image/') || type == 'image/svg+xml') {
        throw Errors.invalid('The URL is not an image.');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(timeout)) {
        builder.add(chunk);
        if (builder.length > maxBytes) {
          throw Errors.tooLarge('The image is larger than 10 MB.');
        }
      }
      return builder.takeBytes();
    } on TimeoutException {
      throw Errors.unavailable('The image did not load in time.');
    } on SocketException {
      throw Errors.unavailable('The image could not be loaded.');
    } on HttpException {
      throw Errors.unavailable('The image could not be loaded.');
    } finally {
      client.close(force: true);
    }
  }

  /// Loopback, link-local, multicast and private ranges (IPv4 and IPv6).
  static bool isPrivate(InternetAddress a) {
    if (a.isLoopback || a.isLinkLocal || a.isMulticast) return true;
    final b = a.rawAddress;
    if (a.type == InternetAddressType.IPv4) {
      return b[0] == 10 ||
          b[0] == 0 ||
          b[0] == 127 ||
          (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
          (b[0] == 192 && b[1] == 168) ||
          (b[0] == 169 && b[1] == 254) ||
          (b[0] == 100 && b[1] >= 64 && b[1] <= 127);
    }
    // IPv6 unique local (fc00::/7), unspecified, IPv4-mapped private.
    if ((b[0] & 0xfe) == 0xfc) return true;
    if (b.every((x) => x == 0)) return true;
    final mapped =
        b.length == 16 &&
        b.sublist(0, 10).every((x) => x == 0) &&
        b[10] == 0xff &&
        b[11] == 0xff;
    if (mapped) {
      return isPrivate(
        InternetAddress.fromRawAddress(Uint8List.fromList(b.sublist(12))),
      );
    }
    return false;
  }
}

/// Server-side [core.ImageResolver] (Write 07 §4.4): `wonky-file://<uuid>`
/// reads the stored bytes (images of the exported document, or files the
/// actor can read), `https://` goes through [SafeImageFetcher]. Results
/// are cached per export; failures resolve to `null` (placeholder +
/// warning in the exporters).
class ServerImageResolver implements core.ImageResolver {
  ServerImageResolver(
    this.session,
    this.actor, {
    required this.itemId,
    this.fetchRemote = SafeImageFetcher.fetch,
  });

  final Session session;
  final Actor actor;

  /// The exported document's drive item.
  final int itemId;

  /// Remote fetcher (tests inject a fake).
  final Future<Uint8List> Function(String src) fetchRemote;

  final Map<String, Future<core.ResolvedImage?>> _cache = {};

  @override
  Future<core.ResolvedImage?> resolve(String src) =>
      _cache.putIfAbsent(src, () => _resolve(src));

  Future<core.ResolvedImage?> _resolve(String src) async {
    try {
      Uint8List? bytes;
      String? mime;
      if (src.startsWith(core.ImageEmbed.wonkyFileScheme)) {
        final id = UuidValue.withValidation(
          src.substring(core.ImageEmbed.wonkyFileScheme.length),
        );
        final file = await FileService.byUuid(session, id);
        if (file == null || file.status != StoredFileStatus.ready) return null;
        if (file.itemId != itemId &&
            !await FileService.canRead(session, actor, file)) {
          return null;
        }
        final data = await FileService.readBytes(session, file);
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        mime = file.mimeType;
      } else if (src.startsWith('https://')) {
        bytes = await fetchRemote(src);
      }
      if (bytes == null || bytes.isEmpty) return null;
      return describe(bytes, mime: mime);
    } on Object catch (e) {
      session.log('Export image $src unavailable: $e', level: LogLevel.debug);
      return null;
    }
  }

  /// Sniffs type and size of [bytes] (header only); `null` when not a
  /// raster image.
  static core.ResolvedImage? describe(Uint8List bytes, {String? mime}) =>
      core.describeExportImage(bytes);
}
