import 'dart:collection';

/// The text collation of Sheets sorting (07 §2.3), shared by `SORT()`,
/// `SORTN()`, Data › Sort, filter views and pivot groups (CQ-50: one rule):
/// a deterministic key (NFKD-like decomposition, combining marks stripped,
/// ligatures and fullwidth forms expanded, simple case folding), then the
/// original string ordinal as the tie-break.
abstract final class Collation {
  /// Keys kept in the LRU cache (repeated values in large sorts).
  static const cacheSize = 50000;

  static final LinkedHashMap<String, String> _cache =
      LinkedHashMap<String, String>();

  /// Compares [a] and [b]: collation key, then ordinal.
  static int compare(String a, String b) {
    if (identical(a, b) || a == b) return 0;
    final c = key(a).compareTo(key(b));
    return c != 0 ? c : a.compareTo(b);
  }

  /// Compares [a] and [b] with their precomputed keys [keyA] and [keyB]
  /// (from [key]): collation key, then ordinal.
  static int compareKeyed(String a, String keyA, String b, String keyB) {
    if (identical(a, b) || a == b) return 0;
    final c = keyA.compareTo(keyB);
    return c != 0 ? c : a.compareTo(b);
  }

  /// The collation key of [s] (cached, least recently used evicted).
  static String key(String s) {
    final cached = _cache.remove(s);
    if (cached != null) {
      _cache[s] = cached;
      return cached;
    }
    final k = _computeKey(s);
    if (_cache.length >= cacheSize) _cache.remove(_cache.keys.first);
    _cache[s] = k;
    return k;
  }

  static String _computeKey(String s) {
    var ascii = true;
    for (var i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) >= 0x80) {
        ascii = false;
        break;
      }
    }
    if (ascii) return s.toLowerCase();
    final b = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      if (r >= 0x300 && r <= 0x36f) continue; // combining diacritical marks
      if (r >= 0x1ab0 && r <= 0x1aff) continue;
      if (r >= 0x1dc0 && r <= 0x1dff) continue;
      if (r >= 0x20d0 && r <= 0x20ff) continue;
      if (r >= 0xfe20 && r <= 0xfe2f) continue;
      final m = _fold[r];
      if (m != null) {
        b.write(m);
      } else if (r >= 0xff01 && r <= 0xff5e) {
        b.writeCharCode(
          r - 0xfee0,
        ); // fullwidth ASCII (compatibility decomposition)
      } else if (r == 0x3000) {
        b.write(' ');
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }

  static final Map<int, String> _fold = () {
    final m = <int, String>{};
    void add(String from, String to) {
      final f = from.runes.toList();
      for (var i = 0; i < f.length; i++) {
        m[f[i]] = to;
      }
    }

    add('àáâãäåāăąǎǟǡǻȁȃȧạảấầẩẫậắằẳẵặ', 'a');
    add('æǣǽ', 'ae');
    add('çćĉċč', 'c');
    add('ďđ', 'd');
    add('èéêëēĕėęěȅȇȩẹẻẽếềểễệ', 'e');
    add('ĝğġģǧǵ', 'g');
    add('ĥħ', 'h');
    add('ìíîïĩīĭįıǐȉȋịỉ', 'i');
    add('ĳ', 'ij');
    add('ĵǰ', 'j');
    add('ķǩ', 'k');
    add('ĺļľŀł', 'l');
    add('ñńņňŉǹ', 'n');
    add('òóôõöøōŏőơǒǫǭǿȍȏȫȭȯȱọỏốồổỗộớờởỡợ', 'o');
    add('œ', 'oe');
    add('ŕŗřȑȓ', 'r');
    add('śŝşšșſ', 's');
    add('ß', 'ss');
    add('ţťŧț', 't');
    add('þ', 'th');
    add('ùúûüũūŭůűųưǔǖǘǚǜȕȗụủứừửữự', 'u');
    add('ŵẁẃẅ', 'w');
    add('ýÿŷỳỵỷỹ', 'y');
    add('źżžƶ', 'z');
    add('ﬀ', 'ff');
    add('ﬁ', 'fi');
    add('ﬂ', 'fl');
    add('ﬃ', 'ffi');
    add('ﬄ', 'ffl');
    add('ά', 'α');
    add('έ', 'ε');
    add('ή', 'η');
    add('ίϊΐ', 'ι');
    add('ό', 'ο');
    add('ύϋΰ', 'υ');
    add('ώ', 'ω');
    add('ς', 'σ');
    add('ё', 'е');
    add('й', 'и');
    return m;
  }();
}
