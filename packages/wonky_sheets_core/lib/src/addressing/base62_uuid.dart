import 'package:wonky_revlog/base62.dart' as codec;

/// UUID ⇄ 22-character base-62 form used inside stored formula reference
/// tokens (02 §2), with the token helpers of the formula engine.
///
/// The codec itself is `wonky_revlog`'s (one base-62 codec in the suite,
/// CQ-50); this adds the caches of the formula hot paths and [toToken] /
/// [fromToken].
abstract final class Base62Uuid {
  static const String alphabet = codec.base62Digits;
  static const int length = codec.Base62Uuid.length;
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final Map<String, String> _encodeCache = {};
  static final Map<String, String> _decodeCache = {};

  /// Whether [s] is a canonical (dashed) UUID string.
  static bool isUuid(String s) => s.length == 36 && _uuid.hasMatch(s);

  /// Whether [s] is a well-formed 22-char base-62 id.
  static bool isBase62(String s) => codec.Base62Uuid.isValid(s);

  /// Canonical UUID → 22-char base-62.
  static String encode(String uuid) {
    final cached = _encodeCache[uuid];
    if (cached != null) return cached;
    final s = codec.Base62Uuid.encode(uuid);
    if (_encodeCache.length > 200000) _encodeCache.clear();
    _encodeCache[uuid] = s;
    return s;
  }

  /// 22-char base-62 → canonical lower-case UUID. Throws [FormatException]
  /// for malformed input.
  static String decode(String b62) {
    final cached = _decodeCache[b62];
    if (cached != null) return cached;
    final s = codec.Base62Uuid.decode(b62);
    if (_decodeCache.length > 200000) _decodeCache.clear();
    _decodeCache[b62] = s;
    return s;
  }

  /// Id as written into a reference token: UUIDs become base-62; other ids (tests, synthetic
  /// ids) are written verbatim.
  static String toToken(String id) => isUuid(id) ? encode(id) : id;

  /// Inverse of [toToken].
  static String fromToken(String token) =>
      isBase62(token) ? decode(token) : token;
}
