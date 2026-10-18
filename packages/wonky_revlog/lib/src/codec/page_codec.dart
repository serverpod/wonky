import 'dart:convert';

import '../rows/row_change.dart';
import '../schema/rev_schema.dart';
import 'base62.dart';
import 'rev_codec.dart';

/// The body of a bootstrap page (RevLog spec 04 §3.1): NDJSON with a header
/// line naming the tables and their columns, then one line per row
/// `[tableIdx, id62, [values…]]` with values in codec encoding.
abstract final class RevPageCodec {
  /// Encodes [rows] ((table, full row with `id`)).
  static String encode(
    RevSchema schema,
    Iterable<(String, Map<String, Object?>)> rows,
  ) {
    final tables = <String>[];
    final index = <String, int>{};
    final lines = <String>[];
    final memo = <String, String>{};
    for (final (table, row) in rows) {
      final ti = index.putIfAbsent(table, () {
        tables.add(table);
        return tables.length - 1;
      });
      final t = schema.table(table);
      lines.add(
        jsonEncode([
          ti,
          Base62Uuid.encode(row[RowChange.idColumn]! as String),
          [for (final c in t.columns) RevValues.toWire(c, row[c.name], memo)],
        ]),
      );
    }
    final header = jsonEncode({
      's': schema.hash,
      't': tables,
      'c': [
        for (final name in tables)
          [for (final c in schema.table(name).columns) c.name],
      ],
    });
    return ([header, ...lines]).join('\n');
  }

  /// Decodes a page body into (table, full row with `id`). Unknown tables
  /// and columns (a newer compatible schema) are skipped.
  static List<(String, Map<String, Object?>)> decode(
    RevSchema schema,
    String body,
  ) {
    final lines = const LineSplitter().convert(body);
    if (lines.isEmpty) return const [];
    final header = (jsonDecode(lines.first) as Map).cast<String, Object?>();
    final tables = (header['t']! as List).cast<String>();
    final cols = [
      for (final l in header['c']! as List) (l as List).cast<String>(),
    ];
    final out = <(String, Map<String, Object?>)>[];
    final memo = <String, String>{};
    for (final line in lines.skip(1)) {
      if (line.isEmpty) continue;
      final l = jsonDecode(line) as List;
      final ti = l[0] as int;
      final name = tables[ti];
      final table = schema.tryTable(name);
      if (table == null) continue;
      final values = l[2] as List;
      final row = <String, Object?>{
        RowChange.idColumn: Base62Uuid.decode(l[1] as String),
      };
      for (var i = 0; i < cols[ti].length && i < values.length; i++) {
        final c = table.column(cols[ti][i]);
        if (c == null) continue;
        row[c.name] = RevValues.fromWire(c, values[i], memo);
      }
      out.add((name, row));
    }
    return out;
  }
}
