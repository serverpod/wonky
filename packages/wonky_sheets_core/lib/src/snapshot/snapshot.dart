import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../model/schema.dart';
import '../model/workbook_model.dart';

/// Header of a version snapshot (10 §5.1.2).
final class SnapshotHeader {
  /// Creates a header.
  const SnapshotHeader({
    required this.spreadsheetId,
    required this.capturedAt,
    this.engineHlc,
    this.engineVersion,
    this.counts = const {},
    this.keys = const {},
  });

  /// Format id.
  static const String format = 'wonky-sheets-snapshot';

  /// Format version.
  static const int version = 1;

  final String spreadsheetId;
  final DateTime capturedAt;
  final String? engineHlc;
  final String? engineVersion;

  /// Row counts per table.
  final Map<String, int> counts;

  /// Column key map per table: short key → column name.
  final Map<String, Map<String, String>> keys;

  /// JSON map.
  Map<String, Object?> toJson() => {
    'format': format,
    'v': version,
    'spreadsheetId': spreadsheetId,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    'engineHlc': ?engineHlc,
    'engineVersion': ?engineVersion,
    'counts': counts,
    'keys': keys,
  };

  /// From JSON.
  static SnapshotHeader fromJson(Map<String, Object?> m) {
    if (m['format'] != format) {
      throw const FormatException('Not a Wonky Sheets snapshot');
    }
    final v = m['v'];
    if (v is! int || v > version) {
      throw FormatException('Unsupported snapshot version $v');
    }
    return SnapshotHeader(
      spreadsheetId: m['spreadsheetId']! as String,
      capturedAt: DateTime.parse(m['capturedAt']! as String),
      engineHlc: m['engineHlc'] as String?,
      engineVersion: m['engineVersion'] as String?,
      counts: {
        for (final e in ((m['counts'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      },
      keys: {
        for (final e in ((m['keys'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as Map).cast<String, String>(),
      },
    );
  }
}

/// A decoded snapshot.
final class Snapshot {
  /// Creates a snapshot.
  const Snapshot(this.header, this.rows);

  final SnapshotHeader header;

  /// `(table, full columns)` in table dependency order.
  final List<(String table, Map<String, Object?> columns)> rows;

  /// Builds a read-only in-memory model (version viewing, exports, diffs).
  WorkbookModel toModel() => WorkbookModel.fromRows(header.spreadsheetId, rows);

  /// Rows of one table.
  Iterable<Map<String, Object?>> table(String name) =>
      rows.where((r) => r.$1 == name).map((r) => r.$2);
}

/// Version snapshot codec: gzip of a JSON header line followed by NDJSON
/// records `{"tb": table, "row": {…}}` grouped by table in dependency order,
/// with per-table abbreviated column keys and null columns omitted
/// (10 §5.1.2).
abstract final class SnapshotCodec {
  /// Tables never stored in snapshots (history, derived, per-installer).
  static const excludedTables = {
    SheetsTables.changeLog,
    SheetsTables.scriptBuild,
    SheetsTables.scriptTrigger,
  };

  /// Encodes rows (any order; they are grouped by table here).
  static Uint8List encode(
    Iterable<(String table, Map<String, Object?> columns)> rows, {
    required String spreadsheetId,
    required DateTime capturedAt,
    String? engineHlc,
    String? engineVersion,
  }) {
    final byTable = <String, List<Map<String, Object?>>>{};
    for (final (t, c) in rows) {
      if (excludedTables.contains(t)) continue;
      (byTable[t] ??= []).add(c);
    }
    final tables = byTable.keys.toList()
      ..sort((a, b) {
        final c = SheetsTables.rank(a).compareTo(SheetsTables.rank(b));
        return c != 0 ? c : a.compareTo(b);
      });
    final keys = <String, Map<String, String>>{};
    final reverse = <String, Map<String, String>>{};
    for (final t in tables) {
      final cols = <String>{for (final r in byTable[t]!) ...r.keys}.toList()
        ..sort();
      final m = <String, String>{};
      final rv = <String, String>{};
      for (var i = 0; i < cols.length; i++) {
        final k = i.toRadixString(36);
        m[k] = cols[i];
        rv[cols[i]] = k;
      }
      keys[t] = m;
      reverse[t] = rv;
    }
    final header = SnapshotHeader(
      spreadsheetId: spreadsheetId,
      capturedAt: capturedAt,
      engineHlc: engineHlc,
      engineVersion: engineVersion,
      counts: {for (final t in tables) t: byTable[t]!.length},
      keys: keys,
    );
    final b = StringBuffer()..writeln(jsonEncode(header.toJson()));
    for (final t in tables) {
      final rv = reverse[t]!;
      for (final r in byTable[t]!) {
        final row = <String, Object?>{};
        r.forEach((k, v) {
          if (v == null) return;
          row[rv[k]!] = _encodeValue(v);
        });
        b.writeln(jsonEncode({'tb': t, 'row': row}));
      }
    }
    return Uint8List.fromList(
      const GZipEncoder().encode(utf8.encode(b.toString())),
    );
  }

  /// Encodes the full state of [model].
  static Uint8List encodeModel(
    WorkbookModel model, {
    required DateTime capturedAt,
    String? engineHlc,
  }) => encode(
    model.allRows(),
    spreadsheetId: model.spreadsheetId,
    capturedAt: capturedAt,
    engineHlc: engineHlc,
  );

  /// Decodes a snapshot. Throws [FormatException] for invalid data.
  static Snapshot decode(List<int> bytes) {
    final String text;
    try {
      text = utf8.decode(const GZipDecoder().decodeBytes(bytes));
    } on Object catch (e) {
      throw FormatException('Invalid snapshot: $e');
    }
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) throw const FormatException('Empty snapshot');
    final header = SnapshotHeader.fromJson(
      (jsonDecode(lines.first) as Map).cast<String, Object?>(),
    );
    final rows = <(String, Map<String, Object?>)>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      final m = jsonDecode(line) as Map;
      final t = m['tb'] as String;
      final keyMap = header.keys[t] ?? const {};
      final row = <String, Object?>{};
      (m['row'] as Map).forEach((k, v) {
        row[keyMap[k] ?? k as String] = _decodeValue(v);
      });
      rows.add((t, row));
    }
    return Snapshot(header, rows);
  }

  static Object? _encodeValue(Object v) {
    if (v is DateTime) return {r'$d': v.toUtc().toIso8601String()};
    if (v is Enum) return v.name;
    return v;
  }

  static Object? _decodeValue(Object? v) {
    if (v is Map && v.length == 1 && v.containsKey(r'$d')) {
      return DateTime.parse(v[r'$d'] as String);
    }
    return v;
  }
}
