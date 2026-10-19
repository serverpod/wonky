import 'dart:collection';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../write/export/server_images.dart';
import '../common/actor.dart';
import '../sharing/access_service.dart';

/// The image proxy of every app (Slides 03 A-03-4, generalized from Sheets'
/// `sheets.fetchImage`): *Insert image ▸ By URL* loads remote images
/// through the server, so clients never contact arbitrary hosts (no CORS
/// problems on the web) and private addresses are refused
/// ([SafeImageFetcher]: https on the default port, public addresses, no
/// redirects, ≤ 10 MB, image types). The caller needs access to the drive
/// item the image goes into. Fetched images are cached in memory for 24 h
/// (LRU, bounded).
abstract final class FileImageProxy {
  static const ttl = Duration(hours: 24);
  static const maxCacheBytes = 64 * 1024 * 1024;

  /// Remote fetcher (tests may replace it).
  static Future<Uint8List> Function(String url) fetcher =
      SafeImageFetcher.fetch;

  static final LinkedHashMap<String, (DateTime, Uint8List)> _cache =
      LinkedHashMap();
  static int _bytes = 0;

  /// The bytes of the https image [url] for a viewer of drive item
  /// [itemUuid].
  static Future<ByteData> fetch(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String url,
  ) async {
    await AccessService.require(session, actor, itemUuid, Role.viewer);
    final now = DateTime.now();
    final hit = _cache.remove(url);
    if (hit != null && now.difference(hit.$1) < ttl) {
      _cache[url] = hit;
      return ByteData.sublistView(hit.$2);
    }
    if (hit != null) _bytes -= hit.$2.length;
    await SafeImageFetcher.checkLimit(actor.userId);
    final bytes = await fetcher(url);
    _cache[url] = (now, bytes);
    _bytes += bytes.length;
    while (_bytes > maxCacheBytes && _cache.isNotEmpty) {
      final first = _cache.keys.first;
      _bytes -= _cache.remove(first)!.$2.length;
    }
    return ByteData.sublistView(bytes);
  }

  /// Clears the cache (tests).
  static void clear() {
    _cache.clear();
    _bytes = 0;
  }
}
