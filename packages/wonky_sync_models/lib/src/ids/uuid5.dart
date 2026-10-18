import 'dart:convert';
import 'dart:typed_data';

/// UUIDv5 (RFC 4122 §4.3: SHA-1 of namespace bytes + UTF-8 name, version 5,
/// RFC variant) for one fixed namespace, without per-call parsing (the
/// `Uuid.v5` of `package:uuid` parses and validates the namespace on every
/// call). Equal to `Uuid().v5(namespace, name)`. Internal to the id helpers
/// (not exported by `ids.dart`).
///
/// Hot path (every cell write of a 1M-cell import): the message is built in
/// a reused buffer (ASCII names are copied code unit by code unit), SHA-1
/// runs on 32-bit words without per-block allocations, and the result is
/// formatted from a code unit table.
final class Uuid5 {
  /// A hasher for the dashed lower-case UUID [namespace].
  Uuid5(String namespace) {
    final hex = namespace.replaceAll('-', '');
    for (var i = 0; i < 16; i++) {
      _buf[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
  }

  /// Namespace bytes followed by the name, padded (grows when needed).
  Uint8List _buf = Uint8List(256);
  final Uint32List _w = Uint32List(80);
  final Uint8List _out = Uint8List(36);

  static final Uint8List _hex = Uint8List.fromList(
    '0123456789abcdef'.codeUnits,
  );

  /// `UUIDv5(namespace, name)` as a dashed lower-case UUID string.
  String of(String name) {
    // Message: 16 namespace bytes + UTF-8 name.
    var ml = 16;
    final n = name.length;
    _ensure(16 + n * 3 + 72);
    var ascii = true;
    for (var i = 0; i < n; i++) {
      final c = name.codeUnitAt(i);
      if (c >= 0x80) {
        ascii = false;
        break;
      }
      _buf[ml++] = c;
    }
    if (!ascii) {
      final bytes = utf8.encode(name);
      _ensure(16 + bytes.length + 72);
      _buf.setRange(16, 16 + bytes.length, bytes);
      ml = 16 + bytes.length;
    }
    // Padding: 0x80, zeros, 64-bit big-endian bit length.
    final total = ((ml + 8) ~/ 64 + 1) * 64;
    final buf = _buf;
    buf[ml] = 0x80;
    buf.fillRange(ml + 1, total - 8, 0);
    final bits = ml * 8;
    buf[total - 8] = 0;
    buf[total - 7] = 0;
    buf[total - 6] = 0;
    buf[total - 5] = 0;
    buf[total - 4] = (bits >> 24) & 0xff;
    buf[total - 3] = (bits >> 16) & 0xff;
    buf[total - 2] = (bits >> 8) & 0xff;
    buf[total - 1] = bits & 0xff;

    var h0 = 0x67452301, h1 = 0xefcdab89, h2 = 0x98badcfe;
    var h3 = 0x10325476, h4 = 0xc3d2e1f0;
    final w = _w;
    for (var off = 0; off < total; off += 64) {
      for (var i = 0; i < 16; i++) {
        final j = off + i * 4;
        w[i] =
            (buf[j] << 24) |
            (buf[j + 1] << 16) |
            (buf[j + 2] << 8) |
            buf[j + 3];
      }
      for (var i = 16; i < 80; i++) {
        final x = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
        w[i] = (x << 1) | (x >> 31);
      }
      var a = h0, b = h1, c = h2, d = h3, e = h4;
      for (var i = 0; i < 20; i++) {
        final t =
            ((((a << 5) | (a >> 27)) & 0xffffffff) +
                ((b & c) | (~b & d)) +
                e +
                0x5a827999 +
                w[i]) &
            0xffffffff;
        e = d;
        d = c;
        c = ((b << 30) | (b >> 2)) & 0xffffffff;
        b = a;
        a = t;
      }
      for (var i = 20; i < 40; i++) {
        final t =
            ((((a << 5) | (a >> 27)) & 0xffffffff) +
                (b ^ c ^ d) +
                e +
                0x6ed9eba1 +
                w[i]) &
            0xffffffff;
        e = d;
        d = c;
        c = ((b << 30) | (b >> 2)) & 0xffffffff;
        b = a;
        a = t;
      }
      for (var i = 40; i < 60; i++) {
        final t =
            ((((a << 5) | (a >> 27)) & 0xffffffff) +
                ((b & c) | (b & d) | (c & d)) +
                e +
                0x8f1bbcdc +
                w[i]) &
            0xffffffff;
        e = d;
        d = c;
        c = ((b << 30) | (b >> 2)) & 0xffffffff;
        b = a;
        a = t;
      }
      for (var i = 60; i < 80; i++) {
        final t =
            ((((a << 5) | (a >> 27)) & 0xffffffff) +
                (b ^ c ^ d) +
                e +
                0xca62c1d6 +
                w[i]) &
            0xffffffff;
        e = d;
        d = c;
        c = ((b << 30) | (b >> 2)) & 0xffffffff;
        b = a;
        a = t;
      }
      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
    }
    // Version 5 and the RFC variant, formatted as 8-4-4-4-12.
    h1 = (h1 & 0xffff0fff) | 0x00005000;
    h2 = (h2 & 0x3fffffff) | 0x80000000;
    final out = _out;
    _word(out, 0, h0);
    out[8] = 0x2d;
    _half(out, 9, h1 >> 16);
    out[13] = 0x2d;
    _half(out, 14, h1 & 0xffff);
    out[18] = 0x2d;
    _half(out, 19, h2 >> 16);
    out[23] = 0x2d;
    _half(out, 24, h2 & 0xffff);
    _word(out, 28, h3);
    return String.fromCharCodes(out);
  }

  void _ensure(int n) {
    if (n <= _buf.length) return;
    _buf = Uint8List(n * 2)..setRange(0, 16, _buf);
  }

  static void _word(Uint8List out, int at, int v) {
    _half(out, at, v >> 16);
    _half(out, at + 4, v & 0xffff);
  }

  static void _half(Uint8List out, int at, int v) {
    out[at] = _hex[(v >> 12) & 0xf];
    out[at + 1] = _hex[(v >> 8) & 0xf];
    out[at + 2] = _hex[(v >> 4) & 0xf];
    out[at + 3] = _hex[v & 0xf];
  }
}
