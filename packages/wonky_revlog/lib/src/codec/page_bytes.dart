import 'dart:convert';
import 'dart:typed_data';

/// Byte helpers of the binary page format (RevLog spec 04 §3.1): a growable
/// writer and a bounds-checked reader with unsigned varints. Integers are
/// handled with arithmetic, not bit operations, so they stay exact on the
/// web up to 2^53.
final class PageWriter {
  /// Creates a writer with [capacity] initial bytes.
  PageWriter([int capacity = 1024])
    : _b = Uint8List(capacity < 16 ? 16 : capacity);

  Uint8List _b;
  ByteData? _data;
  int _n = 0;

  /// Bytes written.
  int get length => _n;

  void _ensure(int k) {
    if (_n + k <= _b.length) return;
    var cap = _b.length * 2;
    while (cap < _n + k) {
      cap *= 2;
    }
    _b = Uint8List(cap)..setRange(0, _n, _b);
    _data = null;
  }

  /// One byte.
  void byte(int v) {
    _ensure(1);
    _b[_n++] = v;
  }

  /// An unsigned varint (7 bits per byte, low groups first).
  void varint(int v) {
    assert(v >= 0, 'varint of a negative value');
    _ensure(10);
    while (v >= 128) {
      _b[_n++] = (v % 128) + 128;
      v = v ~/ 128;
    }
    _b[_n++] = v;
  }

  /// A signed integer as a zigzag varint.
  void zigzag(int v) => varint(v >= 0 ? v * 2 : -v * 2 - 1);

  /// A little-endian float64.
  void float64(double v) {
    _ensure(8);
    (_data ??= ByteData.sublistView(_b)).setFloat64(_n, v, Endian.little);
    _n += 8;
  }

  /// Raw bytes.
  void bytes(List<int> src, [int start = 0, int? end]) {
    final e = end ?? src.length;
    _ensure(e - start);
    _b.setRange(_n, _n + e - start, src, start);
    _n += e - start;
  }

  /// A fixed-width unsigned integer of [width] bytes (1, 2 or 4),
  /// little-endian.
  void fixed(int v, int width) {
    _ensure(width);
    _b[_n++] = v % 256;
    if (width == 1) return;
    _b[_n++] = (v ~/ 256) % 256;
    if (width == 2) return;
    _b[_n++] = (v ~/ 65536) % 256;
    _b[_n++] = (v ~/ 16777216) % 256;
  }

  /// A length-prefixed UTF-8 string.
  void string(String s) {
    final u = utf8.encode(s);
    varint(u.length);
    bytes(u);
  }

  /// The bytes written so far (a view; the writer must not be used after).
  Uint8List take() => Uint8List.sublistView(_b, 0, _n);
}

/// Thrown by [PageReader] for truncated or malformed input.
final class PageFormatError implements Exception {
  /// Creates the error.
  PageFormatError(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'PageFormatError: $message';
}

/// A bounds-checked reader over [bytes].
final class PageReader {
  /// Reads [bytes] from [start].
  PageReader(this.bytes, [this.pos = 0]) : end = bytes.length;

  /// The input.
  final Uint8List bytes;

  /// The next position.
  int pos;

  /// The end of the input.
  final int end;

  ByteData? _data;

  /// Whether every byte was read.
  bool get atEnd => pos >= end;

  void _need(int k) {
    if (pos + k > end) throw PageFormatError('truncated at $pos (+$k)');
  }

  /// One byte.
  int byte() {
    _need(1);
    return bytes[pos++];
  }

  /// An unsigned varint.
  int varint() {
    var result = 0;
    var scale = 1;
    for (var i = 0; i < 9; i++) {
      _need(1);
      final b = bytes[pos++];
      if (b < 128) return result + b * scale;
      result += (b - 128) * scale;
      scale *= 128;
    }
    throw PageFormatError('varint too long at $pos');
  }

  /// A zigzag varint.
  int zigzag() {
    final z = varint();
    return z.isEven ? z ~/ 2 : -((z + 1) ~/ 2);
  }

  /// A little-endian float64.
  double float64() {
    _need(8);
    final v = (_data ??= ByteData.sublistView(
      bytes,
    )).getFloat64(pos, Endian.little);
    pos += 8;
    return v;
  }

  /// A fixed-width unsigned integer (see [PageWriter.fixed]).
  int fixed(int width) {
    _need(width);
    final b = bytes;
    final p = pos;
    pos += width;
    return switch (width) {
      1 => b[p],
      2 => b[p] + b[p + 1] * 256,
      _ => b[p] + b[p + 1] * 256 + b[p + 2] * 65536 + b[p + 3] * 16777216,
    };
  }

  /// [length] bytes as a view.
  Uint8List view(int length) {
    _need(length);
    final v = Uint8List.sublistView(bytes, pos, pos + length);
    pos += length;
    return v;
  }

  /// A length-prefixed UTF-8 string.
  String string() => utf8.decode(view(varint()));
}

/// 16-byte UUIDs ⇄ canonical strings (lower-case, dashed).
abstract final class PageUuids {
  static const _hex = '0123456789abcdef';

  /// The 16 bytes of [v]: a UUID string (any case, dashes optional), 16
  /// bytes, or an object whose `toString()` is a UUID (`UuidValue`).
  static Uint8List bytesOf(Object v) {
    if (v is Uint8List && v.length == 16) return v;
    if (v is List<int> && v.length == 16) return Uint8List.fromList(v);
    return parse(v is String ? v : v.toString());
  }

  /// Parses a UUID string.
  static Uint8List parse(String s) {
    final out = Uint8List(16);
    var n = 0;
    var hi = -1;
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x2d) continue;
      final v = c >= 0x30 && c <= 0x39
          ? c - 0x30
          : c >= 0x61 && c <= 0x66
          ? c - 0x57
          : c >= 0x41 && c <= 0x46
          ? c - 0x37
          : -1;
      if (v < 0 || n >= 16) throw FormatException('Invalid UUID', s);
      if (hi < 0) {
        hi = v;
      } else {
        out[n++] = hi * 16 + v;
        hi = -1;
      }
    }
    if (n != 16 || hi >= 0) throw FormatException('Invalid UUID', s);
    return out;
  }

  static final Uint8List _scratch = Uint8List(36);

  /// The canonical string of the 16 bytes of [b] at [offset].
  static String format(Uint8List b, int offset) {
    final out = _scratch;
    var p = 0;
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) out[p++] = 0x2d;
      final v = b[offset + i];
      out[p++] = _hex.codeUnitAt(v >> 4);
      out[p++] = _hex.codeUnitAt(v & 15);
    }
    return String.fromCharCodes(out);
  }
}
