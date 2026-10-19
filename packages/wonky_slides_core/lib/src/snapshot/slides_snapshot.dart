import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../model/api/deck_model.dart';
import '../schema/slides_schema.dart';

/// Header of a deck version snapshot (Slides 09 §4.1): the first NDJSON line
/// `{"format":"wonky-slides-snapshot","v":1,"deckId",…}`.
final class SlidesSnapshotHeader {
  /// Creates a header.
  const SlidesSnapshotHeader({
    required this.deckId,
    required this.capturedAt,
    this.engineHlc,
    this.counts = const {},
    this.keys = const {},
  });

  /// Format id.
  static const String format = 'wonky-slides-snapshot';

  /// Format version.
  static const int version = 1;

  /// The deck (= space) id.
  final String deckId;
  final DateTime capturedAt;

  /// The sync engine's clock at capture (diagnostics).
  final String? engineHlc;

  /// Hash of the synced table definitions at capture: a snapshot of an
  /// older schema still decodes (records are lenient), the hash tells why
  /// columns are missing.

  /// Row counts per table.
  final Map<String, int> counts;

  /// Column key map per table: short key → column name (absent: full
  /// column names, the server's writer may use them).
  final Map<String, Map<String, String>> keys;

  /// JSON map.
  Map<String, Object?> toJson() => {
    'format': format,
    'v': version,
    'deckId': deckId,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    'engineHlc': ?engineHlc,
    'counts': counts,
    if (keys.isNotEmpty) 'keys': keys,
  };

  /// From JSON; throws [FormatException] for other formats or newer
  /// versions.
  static SlidesSnapshotHeader fromJson(Map<String, Object?> m) {
    if (m['format'] != format) {
      throw const FormatException('Not a Wonky Slides snapshot');
    }
    final v = m['v'];
    if (v is! int || v > version) {
      throw FormatException('Unsupported snapshot version $v');
    }
    final deckId = m['deckId'];
    final at = DateTime.tryParse('${m['capturedAt']}');
    if (deckId is! String || at == null) {
      throw const FormatException('Invalid snapshot header');
    }
    return SlidesSnapshotHeader(
      deckId: deckId,
      capturedAt: at.toUtc(),
      engineHlc: m['engineHlc'] as String?,
      counts: {
        for (final e in ((m['counts'] as Map?) ?? const {}).entries)
          '${e.key}': (e.value as num).toInt(),
      },
      keys: {
        for (final e in ((m['keys'] as Map?) ?? const {}).entries)
          '${e.key}': (e.value as Map).cast<String, String>(),
      },
    );
  }
}

/// A decoded deck snapshot: the header and every row in dependency order.
final class SlidesSnapshot {
  /// Creates a snapshot.
  const SlidesSnapshot(this.header, this.rows);

  final SlidesSnapshotHeader header;

  /// `(table, full columns)` in [SlidesTables.dependencyOrder] (elements
  /// with parents before children).
  final List<(String table, Map<String, Object?> columns)> rows;

  /// A read-only in-memory deck (viewing a version, diffs, copies, PDF).
  DeckModel toModel() => DeckModel.fromRows(header.deckId, rows);

  /// Rows of one table.
  Iterable<Map<String, Object?>> table(String name) =>
      rows.where((r) => r.$1 == name).map((r) => r.$2);

  /// Rows by table and id (restore diffs).
  Map<String, Map<String, Map<String, Object?>>> byTable() {
    final out = <String, Map<String, Map<String, Object?>>>{};
    for (final (t, c) in rows) {
      (out[t] ??= {})['${c[SlidesCols.id]}'] = c;
    }
    return out;
  }
}

/// Version snapshot codec of Slides (09 §4.1, the Sheets format): gzip of a
/// JSON header line followed by NDJSON records `{"tb": table, "row": {…}}`
/// for every synced Slides table in dependency order (deck, themes,
/// masters, layouts, groups, slides, elements — parents first —, table
/// axes, cells, builds, code states, chart links). The change log is never
/// stored. Columns are abbreviated per table (header `keys`) and null
/// columns omitted; `DateTime`s are `{"$d": iso}`.
abstract final class SlidesSnapshotCodec {
  /// Tables never stored in snapshots (history).
  static const excludedTables = {SlidesTables.deckChangeLog};

  /// Encodes [rows] (any order; grouped by table, elements parents first).
  static Uint8List encode(
    Iterable<(String table, Map<String, Object?> columns)> rows, {
    required String deckId,
    required DateTime capturedAt,
    String? engineHlc,
  }) {
    final byTable = <String, List<Map<String, Object?>>>{};
    for (final (t, c) in rows) {
      if (excludedTables.contains(t)) continue;
      (byTable[t] ??= []).add(c);
    }
    final elements = byTable[SlidesTables.slideElement];
    if (elements != null) {
      byTable[SlidesTables.slideElement] = parentsFirst(elements);
    }
    final tables = byTable.keys.toList()
      ..sort((a, b) {
        final c = SlidesTables.rank(a).compareTo(SlidesTables.rank(b));
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
    final header = SlidesSnapshotHeader(
      deckId: deckId,
      capturedAt: capturedAt,
      engineHlc: engineHlc,
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

  /// Encodes every row of [model].
  static Uint8List encodeModel(
    DeckModel model, {
    required DateTime capturedAt,
    String? engineHlc,
  }) => encode(
    [
      for (final t in SlidesTables.dependencyOrder)
        for (final r in model.records(t)) (t, r.toColumns()),
    ],
    deckId: model.deckId,
    capturedAt: capturedAt,
    engineHlc: engineHlc,
  );

  /// Decodes a snapshot. Throws [FormatException] for invalid data.
  static SlidesSnapshot decode(List<int> bytes) {
    final String text;
    try {
      text = utf8.decode(const GZipDecoder().decodeBytes(bytes));
    } on Object catch (e) {
      throw FormatException('Invalid snapshot: $e');
    }
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) throw const FormatException('Empty snapshot');
    final Object? first;
    try {
      first = jsonDecode(lines.first);
    } on FormatException {
      throw const FormatException('Invalid snapshot header');
    }
    if (first is! Map) throw const FormatException('Invalid snapshot header');
    final header = SlidesSnapshotHeader.fromJson(first.cast<String, Object?>());
    final rows = <(String, Map<String, Object?>)>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      final m = jsonDecode(line);
      if (m is! Map || m['tb'] is! String || m['row'] is! Map) {
        throw FormatException('Invalid snapshot record on line ${i + 1}');
      }
      final t = m['tb'] as String;
      if (excludedTables.contains(t)) continue;
      final keyMap = header.keys[t] ?? const {};
      final row = <String, Object?>{};
      (m['row'] as Map).forEach((k, v) {
        row[keyMap[k] ?? '$k'] = _decodeValue(v);
      });
      if (row[SlidesCols.id] is! String) continue;
      rows.add((t, row));
    }
    rows.sort(
      (a, b) => SlidesTables.rank(a.$1).compareTo(SlidesTables.rank(b.$1)),
    );
    return SlidesSnapshot(header, rows);
  }

  /// [elements] ordered so that every group comes before its children
  /// (stable otherwise; cycles and missing parents keep their place).
  static List<Map<String, Object?>> parentsFirst(
    List<Map<String, Object?>> elements,
  ) {
    final byId = {for (final e in elements) '${e[SlidesCols.id]}': e};
    final out = <Map<String, Object?>>[];
    final placed = <String>{};
    final visiting = <String>{};
    void place(Map<String, Object?> e) {
      final id = '${e[SlidesCols.id]}';
      if (placed.contains(id) || !visiting.add(id)) return;
      final parent = e[SlidesCols.parentId];
      final p = parent == null ? null : byId['$parent'];
      if (p != null) place(p);
      visiting.remove(id);
      if (placed.add(id)) out.add(e);
    }

    for (final e in elements) {
      place(e);
    }
    return out;
  }

  static Object? _encodeValue(Object v) {
    if (v is DateTime) return {r'$d': v.toUtc().toIso8601String()};
    if (v is Enum) return v.name;
    return v;
  }

  static Object? _decodeValue(Object? v) {
    if (v is Map && v.length == 1 && v.containsKey(r'$d')) {
      return DateTime.tryParse('${v[r'$d']}')?.toUtc();
    }
    return v;
  }
}
