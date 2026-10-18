/// Base-62 helpers shared by the id codec and the fractional index.
///
/// The alphabet is in ASCII order (`0-9A-Za-z`), so lexicographic comparison of
/// equal-length base-62 strings equals numeric comparison.
library;

/// The base-62 alphabet in ASCII order.
const String base62Digits =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

final List<int> _digitValues = () {
  final table = List<int>.filled(128, -1);
  for (var i = 0; i < base62Digits.length; i++) {
    table[base62Digits.codeUnitAt(i)] = i;
  }
  return table;
}();

/// Value of a base-62 digit code unit, or -1 if [codeUnit] is not a digit.
int base62Value(int codeUnit) => codeUnit < 128 ? _digitValues[codeUnit] : -1;

/// Codec between UUIDs and their 22-character base-62 form used inside
/// stored formula reference tokens (`⟦R:<id22>;C:<id22>⟧`, specs/wonky_sheets/02 §2).
///
/// The 128-bit UUID value is written big-endian in base 62, left-padded with
/// `0` to 22 characters (62^22 > 2^128). Encoding preserves order: comparing two
/// encodings as strings compares the UUIDs numerically. Implemented with byte
/// long-division so it is exact on the web (no 64-bit ints, no BigInt).
abstract final class Base62Uuid {
  /// Length of an encoded id.
  static const int length = 22;

  /// 62^5: five base-62 digits per division step (< 2^30, so a 16-bit limb
  /// times it stays exact on the web).
  static const int _d5 = 916132832;

  /// Encodes a UUID string (`xxxxxxxx-xxxx-…`, any case, dashes optional).
  static String encode(String uuid) => _encodeLimbs(_parseUuid(uuid));

  /// Encodes 16 raw UUID bytes.
  static String encodeBytes(List<int> bytes) {
    if (bytes.length != 16) {
      throw ArgumentError.value(bytes.length, 'bytes', 'must be 16 bytes');
    }
    return _encodeLimbs([
      for (var i = 0; i < 8; i++) bytes[2 * i] << 8 | bytes[2 * i + 1],
    ]);
  }

  /// Encodes eight big-endian 16-bit limbs (consumed): long division by
  /// 62^5 yields five digits per pass (5 passes instead of 22).
  static String _encodeLimbs(List<int> work) {
    final out = List<int>.filled(length, 0x30);
    var pos = length - 1;
    for (var pass = 0; pass < 5; pass++) {
      var rem = 0;
      for (var i = 0; i < 8; i++) {
        final acc = rem * 65536 + work[i];
        final q = acc ~/ _d5;
        work[i] = q;
        rem = acc - q * _d5;
      }
      for (var k = 0; k < 5 && pos >= 0; k++, pos--) {
        out[pos] = base62Digits.codeUnitAt(rem % 62);
        rem ~/= 62;
      }
    }
    return String.fromCharCodes(out);
  }

  /// Decodes a 22-char base-62 id to the canonical lower-case dashed UUID string.
  /// Throws [FormatException] for malformed input.
  static String decode(String id22) => _formatUuid(decodeBytes(id22));

  /// Decodes a 22-char base-62 id to 16 bytes. Throws [FormatException].
  static List<int> decodeBytes(String id22) {
    if (id22.length != length) {
      throw FormatException('Base-62 id must be $length characters', id22);
    }
    // 8 big-endian 16-bit limbs; digits are folded in groups of 2 + 4 × 5.
    final limbs = List<int>.filled(8, 0);
    var p = 0;
    while (p < length) {
      final n = p == 0 ? 2 : 5;
      var chunk = 0;
      var scale = 1;
      for (var k = 0; k < n; k++, p++) {
        final d = base62Value(id22.codeUnitAt(p));
        if (d < 0) throw FormatException('Invalid base-62 digit', id22, p);
        chunk = chunk * 62 + d;
        scale *= 62;
      }
      // limbs = limbs * 62^n + chunk
      var carry = chunk;
      for (var i = 7; i >= 0; i--) {
        final acc = limbs[i] * scale + carry;
        limbs[i] = acc % 65536;
        carry = acc ~/ 65536;
      }
      if (carry != 0) {
        throw FormatException('Base-62 id overflows 128 bits', id22);
      }
    }
    return [
      for (final l in limbs) ...[l >> 8, l & 0xff],
    ];
  }

  /// Whether [s] is a well-formed 22-char base-62 id.
  static bool isValid(String s) {
    if (s.length != length) return false;
    for (var i = 0; i < s.length; i++) {
      if (base62Value(s.codeUnitAt(i)) < 0) return false;
    }
    try {
      decodeBytes(s);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// The eight big-endian 16-bit limbs of a UUID string (dashes ignored).
  static List<int> _parseUuid(String uuid) {
    final limbs = List<int>.filled(8, 0);
    var n = 0;
    for (var i = 0; i < uuid.length; i++) {
      final c = uuid.codeUnitAt(i);
      if (c == 0x2d) continue; // '-'
      final v = _hexValue(c);
      if (v < 0 || n >= 32) throw FormatException('Invalid UUID', uuid);
      limbs[n >> 2] = limbs[n >> 2] << 4 | v;
      n++;
    }
    if (n != 32) throw FormatException('Invalid UUID', uuid);
    return limbs;
  }

  static int _hexValue(int c) {
    if (c >= 0x30 && c <= 0x39) return c - 0x30;
    if (c >= 0x61 && c <= 0x66) return c - 0x57;
    if (c >= 0x41 && c <= 0x46) return c - 0x37;
    return -1;
  }

  static const _hex = '0123456789abcdef';

  static String _formatUuid(List<int> b) {
    final out = List<int>.filled(36, 0x2d);
    var p = 0;
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) p++;
      out[p++] = _hex.codeUnitAt(b[i] >> 4);
      out[p++] = _hex.codeUnitAt(b[i] & 0xf);
    }
    return String.fromCharCodes(out);
  }
}
