import 'dart:convert';
import 'dart:typed_data';

import 'package:wonky_revlog/schema.dart';

/// The compact binary encoding of cached rows (RevLog spec 17 As built:
/// client cache layout).
///
/// A row is a sequence of `(column, value)` entries without the null
/// columns and without the columns the cache keeps elsewhere (the id; for
/// cells also the sheet and row keys). A column is its index in
/// [RevTable.columns] plus one (`0` = a column the schema doesn't know,
/// followed by its name). A value is a tag byte and its payload:
///
/// | Tag | Value | Payload |
/// |-----|-------|---------|
/// | 1 / 2 | `false` / `true` | — |
/// | 3 | int | zigzag varint |
/// | 4 | double | 8 bytes, little endian |
/// | 5 | string | varint UTF-8 length, bytes |
/// | 6 | uuid string (canonical, lower case) | 16 bytes |
/// | 7 | `DateTime` (UTC) | zigzag varint of epoch milliseconds |
/// | 8 | other (maps, lists) | as 5, JSON |
///
/// Integers are written with arithmetic instead of bit shifts, so the
/// encoding is the same on the web (JavaScript numbers) and native.
final class RevRowWriter {
  Uint8List _buf = Uint8List(4096);
  late ByteData _data = ByteData.sublistView(_buf);
  int _len = 0;

  /// Bytes written so far.
  int get length => _len;

  /// Starts over (keeps the buffer).
  void clear() => _len = 0;

  /// A copy of the bytes written.
  Uint8List takeBytes() {
    final out = Uint8List.fromList(Uint8List.sublistView(_buf, 0, _len));
    _len = 0;
    return out;
  }

  void _ensure(int n) {
    if (_len + n <= _buf.length) return;
    var size = _buf.length * 2;
    while (size < _len + n) {
      size *= 2;
    }
    final next = Uint8List(size)..setRange(0, _len, _buf);
    _buf = next;
    _data = ByteData.sublistView(_buf);
  }

  /// One byte.
  void byte(int b) {
    _ensure(1);
    _buf[_len++] = b;
  }

  /// An unsigned varint (`0 ≤ v < 2^53`).
  void varint(int v) {
    _ensure(10);
    while (v >= 128) {
      _buf[_len++] = (v % 128) + 128;
      v = v ~/ 128;
    }
    _buf[_len++] = v;
  }

  /// A signed varint (zigzag).
  void zigzag(int v) => varint(v >= 0 ? v * 2 : -v * 2 - 1);

  /// Raw bytes.
  void bytes(List<int> b) {
    _ensure(b.length);
    _buf.setRange(_len, _len + b.length, b);
    _len += b.length;
  }

  /// A length-prefixed UTF-8 string.
  void string(String s) {
    final n = s.length;
    // ASCII fast path (most cell content): one byte per code unit.
    _ensure(n + 10);
    final start = _len;
    varint(n);
    final at = _len;
    var ascii = true;
    for (var i = 0; i < n; i++) {
      final c = s.codeUnitAt(i);
      if (c >= 128) {
        ascii = false;
        break;
      }
      _buf[at + i] = c;
    }
    if (ascii) {
      _len = at + n;
      return;
    }
    _len = start;
    final utf = utf8.encode(s);
    varint(utf.length);
    bytes(utf);
  }

  /// A uuid string as 16 bytes; false (nothing written) when [s] is not a
  /// canonical lower-case uuid.
  bool uuid(String s) {
    if (s.length != 36) return false;
    _ensure(16);
    var o = _len;
    for (var i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        if (s.codeUnitAt(i) != 0x2d) return false;
        continue;
      }
      final hi = _nibble(s.codeUnitAt(i));
      final lo = _nibble(s.codeUnitAt(++i));
      if (hi < 0 || lo < 0) return false;
      _buf[o++] = hi * 16 + lo;
    }
    _len = o;
    return true;
  }

  static int _nibble(int c) {
    if (c >= 0x30 && c <= 0x39) return c - 0x30;
    if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
    return -1;
  }

  /// A tagged value (see [RevRowWriter]).
  void value(Object v) {
    switch (v) {
      case bool():
        byte(v ? 2 : 1);
      case int():
        byte(3);
        zigzag(v);
      case double():
        byte(4);
        _ensure(8);
        _data.setFloat64(_len, v, Endian.little);
        _len += 8;
      case String():
        byte(6);
        if (!uuid(v)) {
          _buf[_len - 1] = 5;
          string(v);
        }
      case DateTime():
        byte(7);
        zigzag(v.toUtc().millisecondsSinceEpoch);
      default:
        byte(8);
        string(jsonEncode(v));
    }
  }

  /// The columns of [row] (a full row of [table]) except `id`, [skip1] and
  /// [skip2] and null values: entry count, then the entries.
  void row(
    RevTable table,
    Map<String, Object?> row, {
    String? skip1,
    String? skip2,
  }) {
    var n = 0;
    for (final e in row.entries) {
      if (e.value != null &&
          e.key != 'id' &&
          e.key != skip1 &&
          e.key != skip2) {
        n++;
      }
    }
    varint(n);
    for (final e in row.entries) {
      final v = e.value;
      if (v == null || e.key == 'id' || e.key == skip1 || e.key == skip2) {
        continue;
      }
      final i = columnIndex(table, e.key);
      if (i < 0) {
        varint(0);
        string(e.key);
      } else {
        varint(i + 1);
      }
      value(v);
    }
  }
}

/// Reads what [RevRowWriter] wrote.
final class RevRowReader {
  /// Reads [bytes].
  RevRowReader(this.bytes) : _data = ByteData.sublistView(bytes);

  /// The input.
  final Uint8List bytes;
  final ByteData _data;
  int _at = 0;

  /// Whether everything was read.
  bool get done => _at >= bytes.length;

  /// One byte.
  int byte() => bytes[_at++];

  /// An unsigned varint.
  int varint() {
    var v = 0;
    var scale = 1;
    while (true) {
      final b = bytes[_at++];
      if (b < 128) return v + b * scale;
      v += (b - 128) * scale;
      scale *= 128;
    }
  }

  /// A signed varint (zigzag).
  int zigzag() {
    final z = varint();
    return z.isEven ? z ~/ 2 : -(z + 1) ~/ 2;
  }

  /// A length-prefixed UTF-8 string.
  String string() {
    final n = varint();
    final start = _at;
    _at += n;
    for (var i = start; i < _at; i++) {
      if (bytes[i] >= 128) return utf8.decode(bytes.sublist(start, _at));
    }
    return String.fromCharCodes(bytes, start, _at);
  }

  static final _hex = '0123456789abcdef'.codeUnits;
  final Uint8List _uuid = Uint8List(36);

  /// 16 bytes as a uuid string.
  String uuid() {
    final out = _uuid;
    var o = 0;
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) out[o++] = 0x2d;
      final b = bytes[_at++];
      out[o++] = _hex[b ~/ 16];
      out[o++] = _hex[b % 16];
    }
    return String.fromCharCodes(out);
  }

  /// A tagged value.
  Object? value() {
    switch (bytes[_at++]) {
      case 1:
        return false;
      case 2:
        return true;
      case 3:
        return zigzag();
      case 4:
        final v = _data.getFloat64(_at, Endian.little);
        _at += 8;
        return v;
      case 5:
        return string();
      case 6:
        return uuid();
      case 7:
        return DateTime.fromMillisecondsSinceEpoch(zigzag(), isUtc: true);
      case 8:
        return jsonDecode(string());
      case final t:
        throw FormatException('Unknown value tag $t in a cached row');
    }
  }

  /// The entries of one row of [table] into [into].
  void row(RevTable table, Map<String, Object?> into) {
    final columns = table.columns;
    for (var n = varint(); n > 0; n--) {
      final c = varint();
      final name = c == 0 ? string() : columns[c - 1].name;
      into[name] = value();
    }
  }
}

final Expando<Map<String, int>> _columnIndexes = Expando();

/// The index of [column] in [table]'s columns, or -1.
int columnIndex(RevTable table, String column) =>
    (_columnIndexes[table] ??= {
      for (var i = 0; i < table.columns.length; i++) table.columns[i].name: i,
    })[column] ??
    -1;
