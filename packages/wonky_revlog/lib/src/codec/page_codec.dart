import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show ZLibDecoder, ZLibEncoder;

import '../rows/row_change.dart';
import '../schema/rev_schema.dart';
import 'base62.dart';
import 'page_bytes.dart';
import 'rev_codec.dart';

/// A decoded page row: (table, full row with `id`).
typedef RevPageRow = (String, Map<String, Object?>);

/// The body of a bootstrap page (RevLog spec 04 §3.1).
///
/// **Version 2** (current) is binary and columnar: per table the row ids
/// once (16 bytes each) and one block per column with a presence bitmap,
/// typed values (UUID and string dictionaries, zigzag varints, float64,
/// bit-packed booleans, delta-coded times) and zlib compression where it
/// pays. **Version 1** is gzip NDJSON of full rows; it is still decoded
/// (an older server) and served to clients that don't ask for a format
/// (04 §3).
///
/// Decoded rows carry `id` and their non-null columns; a null column is
/// left out (it reads back as null, as in the client cache) unless the
/// column has a non-null default, where the null is explicit.
abstract final class RevPageCodec {
  /// The current body version.
  static const version = 2;

  /// The NDJSON version (gzip).
  static const legacyVersion = 1;

  /// The versions [decode] reads.
  static const supported = {legacyVersion, version};

  /// The version a server serves for a request asking for [requested]
  /// (null: a client from before format negotiation).
  static int negotiate(int? requested) {
    if (requested == null || requested < version) return legacyVersion;
    return version;
  }

  /// Encodes [rows] as a version-2 body. Rows of one table are grouped
  /// (tables in order of first appearance, rows in input order).
  static Uint8List encode(
    RevSchema schema,
    Iterable<RevPageRow> rows, {
    bool compress = true,
  }) {
    final byTable = <String, List<Map<String, Object?>>>{};
    for (final (t, r) in rows) {
      (byTable[t] ??= []).add(r);
    }
    final b = RevPageBuilder(schema, compress: compress);
    for (final MapEntry(key: name, value: list) in byTable.entries) {
      final table = schema.table(name);
      b.addTable(
        name,
        [for (final r in list) r[RowChange.idColumn]!],
        {
          for (final c in table.columns)
            c.name: [for (final r in list) r[c.name]],
        },
      );
    }
    return b.build();
  }

  /// Encodes [rows] as a version-1 body (gzip NDJSON with a header line
  /// naming the tables and their columns, then `[tableIdx, id62, [values…]]`
  /// per row).
  static Uint8List encodeLegacy(RevSchema schema, Iterable<RevPageRow> rows) {
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
          Base62Uuid.encode(row[RowChange.idColumn]!.toString()),
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
    return RevCodec.gzip([header, ...lines].join('\n'));
  }

  /// The version of [body]: 1 (gzip) or the version byte of a binary body.
  /// Throws [RevCodecException] for anything else.
  static int versionOf(List<int> body) {
    if (body.length >= 2 && body[0] == 0x1f && body[1] == 0x8b) return 1;
    if (body.length >= 4 &&
        body[0] == _magic0 &&
        body[1] == _magic1 &&
        body[2] == _magic2) {
      return body[3];
    }
    throw RevCodecException('not a page body');
  }

  /// Decodes a page body of any [supported] version. Unknown tables and
  /// columns (a newer compatible schema) are skipped; a known column whose
  /// type differs is an error.
  static List<RevPageRow> decode(RevSchema schema, List<int> body) {
    final out = <RevPageRow>[];
    for (final _ in decodeSteps(schema, body, out)) {}
    return out;
  }

  /// [decode] in steps: rows are appended to [out]; each element of the
  /// iterable ends a slice of work (one column block or up to
  /// [rowsPerStep] rows), so a caller on the UI isolate can yield between
  /// them (web).
  static Iterable<void> decodeSteps(
    RevSchema schema,
    List<int> body,
    List<RevPageRow> out, {
    int rowsPerStep = 2000,
  }) sync* {
    final v = versionOf(body);
    if (v == legacyVersion) {
      out.addAll(_decodeLegacy(schema, RevCodec.gunzip(body)));
      return;
    }
    if (v != version) {
      throw RevCodecException(
        'unsupported page version $v (this app reads ${supported.join(', ')})',
      );
    }
    try {
      yield* _decodeV2(
        schema,
        body is Uint8List ? body : Uint8List.fromList(body),
        out,
        rowsPerStep,
      );
    } on PageFormatError catch (e) {
      throw RevCodecException('bad page: ${e.message}');
    } on FormatException catch (e) {
      throw RevCodecException('bad page: ${e.message}');
    } on RangeError catch (e) {
      throw RevCodecException('bad page: $e');
    }
  }

  static List<RevPageRow> _decodeLegacy(RevSchema schema, String body) {
    final lines = const LineSplitter().convert(body);
    if (lines.isEmpty) return const [];
    final header = (jsonDecode(lines.first) as Map).cast<String, Object?>();
    final tables = (header['t']! as List).cast<String>();
    final cols = [
      for (final l in header['c']! as List) (l as List).cast<String>(),
    ];
    final out = <RevPageRow>[];
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

  // ------------------------------------------------------------ version 2

  static const _magic0 = 0x52; // R
  static const _magic1 = 0x56; // V
  static const _magic2 = 0x50; // P

  static Iterable<void> _decodeV2(
    RevSchema schema,
    Uint8List body,
    List<RevPageRow> out,
    int rowsPerStep,
  ) sync* {
    final r = PageReader(body, 4);
    r.byte(); // flags (reserved)
    r.string(); // schema hash (informational)
    final tables = r.varint();
    for (var t = 0; t < tables; t++) {
      final name = r.string();
      final n = r.varint();
      final columns = r.varint();
      final table = schema.tryTable(name);
      final idBlock = _Block.read(r);
      // Every row has a 16-byte id: bounds every allocation below.
      if (idBlock.payload.length != n * 16) {
        throw PageFormatError('$n rows but ${idBlock.payload.length} id bytes');
      }
      final cols = <(String, List<Object?>?)>[];
      for (var c = 0; c < columns; c++) {
        final colName = r.string();
        final type = r.byte();
        final block = _Block.read(r);
        final column = table?.column(colName);
        if (column == null) continue;
        if (type >= RevColumnType.values.length ||
            RevColumnType.values[type] != column.type) {
          throw RevCodecException(
            'column $name.$colName has type $type, expected '
            '${column.type.name}',
          );
        }
        cols.add((colName, _decodeColumn(column.type, block, n)));
        yield null;
      }
      if (table == null) continue;
      final ids = _decodeIds(idBlock, n);
      // Columns with a non-null default keep explicit nulls (an insert
      // without them would take the default).
      final explicit = <String>[
        for (final c in table.columns)
          if (c.defaultValue != null) c.name,
      ];
      final present = [
        for (final (name, values) in cols)
          if (values != null) (name, values),
      ];
      final nullDefaults = [
        for (final (name, values) in cols)
          if (values == null && explicit.contains(name)) name,
      ];
      final sparseDefaults = [
        for (final (name, _) in present)
          if (explicit.contains(name)) name,
      ];
      for (var i = 0; i < n; i++) {
        final row = <String, Object?>{RowChange.idColumn: ids[i]};
        for (final (name, values) in present) {
          final v = values[i];
          if (v != null) row[name] = v;
        }
        for (final name in nullDefaults) {
          row[name] = null;
        }
        for (final name in sparseDefaults) {
          row.putIfAbsent(name, () => null);
        }
        out.add((name, row));
        if ((i + 1) % rowsPerStep == 0) yield null;
      }
    }
  }

  static List<String> _decodeIds(_Block b, int n) {
    final bytes = b.payload;
    if (b.presence != _all || b.dict || bytes.length != n * 16) {
      throw RevCodecException('bad id block');
    }
    return List<String>.generate(
      n,
      (i) => PageUuids.format(bytes, i * 16),
      growable: false,
    );
  }

  /// The values of a column block, aligned with the rows (null where
  /// absent); null when every value is null.
  static List<Object?>? _decodeColumn(RevColumnType type, _Block b, int n) {
    if (b.presence == _none) return null;
    final r = PageReader(b.payload);
    final Uint8List? bitmap = b.presence == _bitmap
        ? r.view((n + 7) ~/ 8)
        : null;
    final m = bitmap == null ? n : _popCount(bitmap, n);
    final values = _decodeValues(type, r, m, b.dict);
    if (bitmap == null) return values;
    final out = List<Object?>.filled(n, null);
    var k = 0;
    for (var i = 0; i < n; i++) {
      if (bitmap[i >> 3] & (1 << (i & 7)) != 0) out[i] = values[k++];
    }
    return out;
  }

  static int _popCount(Uint8List bitmap, int n) {
    var m = 0;
    for (var i = 0; i < n; i++) {
      if (bitmap[i >> 3] & (1 << (i & 7)) != 0) m++;
    }
    return m;
  }

  static List<Object?> _decodeValues(
    RevColumnType type,
    PageReader r,
    int m,
    bool dict,
  ) {
    switch (type) {
      case RevColumnType.uuid:
        if (!dict) {
          final bytes = r.view(m * 16);
          return List<Object?>.generate(
            m,
            (i) => PageUuids.format(bytes, i * 16),
          );
        }
        final d = r.varint();
        final entries = r.view(d * 16);
        final words = List<String>.generate(
          d,
          (i) => PageUuids.format(entries, i * 16),
        );
        return _indexed(r, m, words);
      case RevColumnType.string || RevColumnType.json || RevColumnType.enumName:
        if (!dict) {
          final lengths = List<int>.generate(m, (_) => r.varint());
          final text = utf8.decode(r.view(r.end - r.pos));
          var p = 0;
          return List<Object?>.generate(m, (i) {
            final s = text.substring(p, p + lengths[i]);
            p += lengths[i];
            return s;
          });
        }
        final d = r.varint();
        if (d > r.end - r.pos) throw PageFormatError('dictionary of $d');
        final lengths = List<int>.generate(d, (_) => r.varint());
        final width = r.byte();
        final indexes = r.view(m * width);
        final text = utf8.decode(r.view(r.end - r.pos));
        var p = 0;
        final words = List<String>.generate(d, (i) {
          final s = text.substring(p, p + lengths[i]);
          p += lengths[i];
          return s;
        });
        return _indexed(PageReader(indexes), m, words, width: width);
      case RevColumnType.int:
        return List<Object?>.generate(m, (_) => r.zigzag());
      case RevColumnType.double:
        return List<Object?>.generate(m, (_) => r.float64());
      case RevColumnType.bool:
        final bits = r.view((m + 7) ~/ 8);
        return List<Object?>.generate(
          m,
          (i) => bits[i >> 3] & (1 << (i & 7)) != 0,
        );
      case RevColumnType.dateTime:
        var prev = 0;
        return List<Object?>.generate(m, (_) {
          prev += r.zigzag();
          return DateTime.fromMillisecondsSinceEpoch(prev, isUtc: true);
        });
    }
  }

  static List<Object?> _indexed(
    PageReader r,
    int m,
    List<String> words, {
    int? width,
  }) {
    final w = width ?? r.byte();
    return List<Object?>.generate(m, (_) {
      final i = r.fixed(w);
      if (i >= words.length) throw PageFormatError('dictionary index $i');
      return words[i];
    });
  }

  static const _none = 0;
  static const _all = 1;
  static const _bitmap = 2;
}

/// One encoded block: `enc` byte (presence in bits 0–1, dictionary bit 2,
/// zlib bit 7), varint length, bytes.
final class _Block {
  _Block(this.presence, this.dict, this.payload);

  final int presence;
  final bool dict;
  final Uint8List payload;

  static const _dictBit = 4;
  static const _zlibBit = 128;

  static _Block read(PageReader r) {
    final enc = r.byte();
    final len = r.varint();
    var payload = r.view(len);
    if (enc & _zlibBit != 0) {
      try {
        payload = const ZLibDecoder().decodeBytes(payload);
      } on Object catch (e) {
        throw PageFormatError('bad compressed block: $e');
      }
    }
    return _Block(enc & 3, enc & _dictBit != 0, payload);
  }

  static void write(
    PageWriter w,
    int presence,
    bool dict,
    Uint8List payload, {
    required bool compress,
  }) {
    var enc = presence | (dict ? _dictBit : 0);
    var bytes = payload;
    if (compress && payload.length >= RevPageBuilder.compressAbove) {
      final z = const ZLibEncoder().encodeBytes(
        payload,
        level: RevPageBuilder.level,
      );
      if (z.length * 5 < payload.length * 4) {
        enc |= _zlibBit;
        bytes = z;
      }
    }
    w
      ..byte(enc)
      ..varint(bytes.length)
      ..bytes(bytes);
  }
}

/// Builds a version-2 page body from columnar input (RevLog spec 04 §3.1):
/// the server's typed SQL rows go in without row maps.
final class RevPageBuilder {
  /// Creates a builder for [schema]; with [compress], blocks that shrink by
  /// at least 20 % are zlib-compressed.
  RevPageBuilder(this.schema, {this.compress = true});

  /// The schema.
  final RevSchema schema;

  /// Whether to compress blocks.
  final bool compress;

  /// Blocks smaller than this are never compressed.
  static int compressAbove = 256;

  /// zlib level.
  static int level = 1;

  final List<Uint8List> _tables = [];

  /// Adds [ids].length rows of [table]. [ids] are UUID strings or 16 bytes;
  /// [columns] maps column names to values aligned with [ids] (null where
  /// the column is null), in-memory or wire form: UUIDs as strings, 16
  /// bytes or `UuidValue`s; times as `DateTime`, ISO strings or epoch
  /// milliseconds; enums as `Enum`s or names. Columns of the table missing
  /// from [columns] are written as all-null; unknown names are an error.
  void addTable(
    String table,
    List<Object> ids,
    Map<String, List<Object?>> columns,
  ) {
    final t = schema.table(table);
    for (final name in columns.keys) {
      if (t.column(name) == null) {
        throw RevCodecException('unknown column $table.$name');
      }
    }
    final n = ids.length;
    final w = PageWriter(64 + n * 24)
      ..string(table)
      ..varint(n)
      ..varint(t.columns.length);
    final idBytes = PageWriter(n * 16 + 16);
    for (final id in ids) {
      idBytes.bytes(PageUuids.bytesOf(id));
    }
    _Block.write(w, RevPageCodec._all, false, idBytes.take(), compress: false);
    for (final c in t.columns) {
      final values = columns[c.name];
      if (values != null && values.length != n) {
        throw RevCodecException(
          'column $table.${c.name}: ${values.length} '
          'values for $n rows',
        );
      }
      w
        ..string(c.name)
        ..byte(c.type.index);
      _writeColumn(w, c, values, n);
    }
    _tables.add(w.take());
  }

  void _writeColumn(PageWriter w, RevColumn c, List<Object?>? values, int n) {
    var m = 0;
    if (values != null) {
      for (final v in values) {
        if (v != null) m++;
      }
    }
    if (m == 0) {
      _Block.write(w, RevPageCodec._none, false, Uint8List(0), compress: false);
      return;
    }
    final p = PageWriter(16 + m * 4);
    final int presence;
    if (m == n) {
      presence = RevPageCodec._all;
    } else {
      presence = RevPageCodec._bitmap;
      final bitmap = Uint8List((n + 7) ~/ 8);
      for (var i = 0; i < n; i++) {
        if (values![i] != null) bitmap[i >> 3] |= 1 << (i & 7);
      }
      p.bytes(bitmap);
    }
    final present = m == n ? values! : [for (final v in values!) ?v];
    final dict = _writeValues(p, c, present);
    final uuidRaw = c.type == RevColumnType.uuid && !dict;
    _Block.write(w, presence, dict, p.take(), compress: compress && !uuidRaw);
  }

  /// Writes the present values; returns whether a dictionary was used.
  static bool _writeValues(PageWriter p, RevColumn c, List<Object?> values) {
    final m = values.length;
    switch (c.type) {
      case RevColumnType.uuid:
        final index = <Object, int>{};
        final words = <Object>[];
        final at = Int32List(m);
        var dict = true;
        for (var i = 0; i < m; i++) {
          final v = values[i]!;
          final key = v is String
              ? v
              : String.fromCharCodes(PageUuids.bytesOf(v));
          final k = index[key];
          if (k != null) {
            at[i] = k;
          } else {
            at[i] = index[key] = words.length;
            words.add(v);
            if (words.length > 16 && words.length * 2 > m) {
              dict = false;
              break;
            }
          }
        }
        if (!dict) {
          for (final v in values) {
            p.bytes(PageUuids.bytesOf(v!));
          }
          return false;
        }
        p.varint(words.length);
        for (final v in words) {
          p.bytes(PageUuids.bytesOf(v));
        }
        _writeIndexes(p, at, words.length);
        return true;
      case RevColumnType.string || RevColumnType.json || RevColumnType.enumName:
        final strings = [
          for (final v in values) v is Enum ? v.name : v.toString(),
        ];
        final index = <String, int>{};
        final at = Int32List(m);
        var dict = true;
        for (var i = 0; i < m; i++) {
          final s = strings[i];
          final k = index[s];
          if (k != null) {
            at[i] = k;
          } else {
            at[i] = index[s] = index.length;
            if (index.length > 16 && index.length * 4 > m) {
              dict = false;
              break;
            }
          }
        }
        if (!dict) {
          for (final s in strings) {
            p.varint(s.length);
          }
          p.bytes(utf8.encode(strings.join()));
          return false;
        }
        final words = index.keys.toList();
        p.varint(words.length);
        for (final s in words) {
          p.varint(s.length);
        }
        _writeIndexes(p, at, words.length);
        p.bytes(utf8.encode(words.join()));
        return true;
      case RevColumnType.int:
        for (final v in values) {
          p.zigzag((v! as num).toInt());
        }
        return false;
      case RevColumnType.double:
        for (final v in values) {
          p.float64((v! as num).toDouble());
        }
        return false;
      case RevColumnType.bool:
        final bits = Uint8List((m + 7) ~/ 8);
        for (var i = 0; i < m; i++) {
          if (values[i]! as bool) bits[i >> 3] |= 1 << (i & 7);
        }
        p.bytes(bits);
        return false;
      case RevColumnType.dateTime:
        var prev = 0;
        for (final v in values) {
          final ms = switch (v) {
            DateTime() => v.millisecondsSinceEpoch,
            num() => v.toInt(),
            String() => DateTime.parse(v).millisecondsSinceEpoch,
            _ => throw RevCodecException('not a date: $v'),
          };
          p.zigzag(ms - prev);
          prev = ms;
        }
        return false;
    }
  }

  static void _writeIndexes(PageWriter p, Int32List at, int d) {
    final width = d <= 256
        ? 1
        : d <= 65536
        ? 2
        : 4;
    p.byte(width);
    for (final i in at) {
      p.fixed(i, width);
    }
  }

  /// The body.
  Uint8List build() {
    final w = PageWriter(64 + _tables.fold<int>(0, (s, t) => s + t.length))
      ..byte(RevPageCodec._magic0)
      ..byte(RevPageCodec._magic1)
      ..byte(RevPageCodec._magic2)
      ..byte(RevPageCodec.version)
      ..byte(0)
      ..string(schema.hash)
      ..varint(_tables.length);
    for (final t in _tables) {
      w.bytes(t);
    }
    return w.take();
  }
}
