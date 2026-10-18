import 'dart:collection';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/common/actor.dart';
import '../../write/export/server_images.dart';
import '../sheets_service.dart';

/// Image proxy of Wonky Sheets (08 §10.1–10.2): `IMAGE("https://…")` cells
/// and *Insert image ▸ By URL* load remote images through the server, so
/// clients never contact arbitrary hosts (no CORS issues on web) and private
/// addresses are refused (`SafeImageFetcher`). Fetched images are cached in
/// memory for 24 h (LRU, bounded).
abstract final class SheetsImageProxy {
  static const ttl = Duration(hours: 24);
  static const maxCacheBytes = 64 * 1024 * 1024;

  /// Remote fetcher (tests may replace it).
  static Future<Uint8List> Function(String url) fetcher =
      SafeImageFetcher.fetch;

  static final LinkedHashMap<String, (DateTime, Uint8List)> _cache =
      LinkedHashMap();
  static int _bytes = 0;

  /// The bytes of the https image [url] for a viewer of the spreadsheet
  /// [itemUuid] (drive item or space uuid).
  static Future<ByteData> fetch(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String url,
  ) async {
    await SheetsService.byItemOrSpace(session, actor, itemUuid, Role.viewer);
    final now = clock.now();
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
