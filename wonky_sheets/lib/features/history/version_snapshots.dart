import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_revlog/schema.dart' show RevColumnType;
import 'package:wonky_sheets_core/revlog.dart' show sheetsSchema;

/// Rows of a version snapshot, normalized to the column types the app's
/// model expects (DateTime columns as `DateTime`, doubles as `double`).
typedef SnapshotRows = List<(String table, Map<String, Object?> columns)>;

/// Downloads and decodes version snapshots (Sheets 10 §5.2): the signed URL
/// from `VersionEndpoint.getSnapshotUrl`, the gzip NDJSON decoded by the
/// core `SnapshotCodec`. Keeps the last few snapshots in memory (the
/// previous version is needed for the changes highlight).
class VersionSnapshots {
  VersionSnapshots._();

  static const _keep = 4;
  static final Map<String, Future<SnapshotRows>> _cache = {};

  /// Overrides the download (tests): returns the gzip bytes of a version.
  @visibleForTesting
  static Future<List<int>> Function(UuidValue item, int versionId)? fetch;

  /// The rows of [versionId] of spreadsheet [item].
  static Future<SnapshotRows> load(
    ShellServices services,
    UuidValue item,
    int versionId,
  ) {
    final key = '${item.uuid}/$versionId';
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    final f = _download(services, item, versionId).then(decode);
    _cache[key] = f;
    f.catchError((Object _) {
      _cache.remove(key);
      return const <(String, Map<String, Object?>)>[];
    });
    while (_cache.length > _keep) {
      _cache.remove(_cache.keys.first);
    }
    return f;
  }

  static Future<List<int>> _download(
    ShellServices services,
    UuidValue item,
    int versionId,
  ) async {
    final override = fetch;
    if (override != null) return override(item, versionId);
    final client = services.client;
    if (client == null) throw StateError('Not connected');
    if (Api.simulatedOffline) {
      throw const OfflineException('simulated offline');
    }
    final url = await client.version.getSnapshotUrl(item, versionId);
    final u = url.url;
    if (u == null) throw StateError('The snapshot is not available yet.');
    final r = await http.get(Uri.parse(u));
    if (r.statusCode != 200) {
      throw StateError('Snapshot download failed (${r.statusCode}).');
    }
    return r.bodyBytes;
  }

  /// Decodes snapshot bytes into normalized rows.
  static SnapshotRows decode(List<int> bytes) {
    final snapshot = SnapshotCodec.decode(bytes);
    return [for (final (t, c) in snapshot.rows) (t, normalize(t, c))];
  }

  /// Converts JSON column values (ISO dates, ints for doubles) into the
  /// model's column types through the RevLog schema.
  static Map<String, Object?> normalize(String table, Map<String, Object?> c) {
    final t = sheetsSchema.tryTable(table);
    if (t == null) return c;
    return {
      for (final e in c.entries)
        e.key: switch ((t.column(e.key)?.type, e.value)) {
          (RevColumnType.dateTime, final String v) =>
            DateTime.tryParse(v)?.toUtc() ?? v,
          (RevColumnType.double, final num v) => v.toDouble(),
          (RevColumnType.int, final num v) => v.toInt(),
          (RevColumnType.uuid, final String v) => v.toLowerCase(),
          _ => e.value,
        },
    };
  }

  /// Clears the cache (tests).
  @visibleForTesting
  static void clear() => _cache.clear();
}
