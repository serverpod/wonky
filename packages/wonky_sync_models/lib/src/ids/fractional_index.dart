import 'package:wonky_revlog/base62.dart';

/// Fractional indexing over base-62 keys (Figma / `fractional-indexing`
/// algorithm, specs/wonky_sheets/02 §2).
///
/// Keys consist of an *integer part* whose first character encodes its length
/// (`a`–`z` positive, `A`–`Z` negative) followed by an optional fractional
/// part without trailing `0`. Keys compare with plain string comparison
/// (`String.compareTo`, code-unit order); ties between identical keys
/// generated concurrently are broken by entity id ([compare]).
abstract final class FractionalIndex {
  static const String _zero = '0';
  static const String _smallestInteger = 'A00000000000000000000000000';

  /// The first key of an empty list (`a0`).
  static String first() => between(null, null);

  /// A key strictly between [a] and [b]; `null` means unbounded on that side.
  /// Throws [ArgumentError] if `a >= b` or a key is malformed.
  static String between(String? a, String? b) {
    if (a != null) _validateKey(a);
    if (b != null) _validateKey(b);
    if (a != null && b != null && a.compareTo(b) >= 0) {
      throw ArgumentError('$a >= $b');
    }
    if (a == null) {
      if (b == null) return 'a$_zero';
      final ib = _integerPart(b);
      final fb = b.substring(ib.length);
      if (ib == _smallestInteger) return ib + _midpoint('', fb);
      if (ib.compareTo(b) < 0) return ib;
      final res = _decrementInteger(ib);
      if (res == null) throw StateError('Cannot decrement any more');
      return res;
    }
    if (b == null) {
      final ia = _integerPart(a);
      final fa = a.substring(ia.length);
      final i = _incrementInteger(ia);
      return i ?? ia + _midpoint(fa, null);
    }
    final ia = _integerPart(a);
    final fa = a.substring(ia.length);
    final ib = _integerPart(b);
    final fb = b.substring(ib.length);
    if (ia == ib) return ia + _midpoint(fa, fb);
    final i = _incrementInteger(ia);
    if (i == null) throw StateError('Cannot increment any more');
    if (i.compareTo(b) < 0) return i;
    return ia + _midpoint(fa, null);
  }

  /// A key before [a] (or the first key if `a` is null).
  static String before(String? a) => between(null, a);

  /// A key after [b] (or the first key if `b` is null).
  static String after(String? b) => between(b, null);

  /// [n] ascending keys strictly between [a] and [b]. Bounded intervals are
  /// split recursively, so the keys are evenly spaced and short; unbounded
  /// ends use consecutive integers (`a0, a1, …`).
  static List<String> nBetween(String? a, String? b, int n) {
    if (n < 0) throw ArgumentError.value(n, 'n');
    if (n == 0) return const [];
    if (n == 1) return [between(a, b)];
    if (b == null) {
      var c = between(a, b);
      final result = [c];
      for (var i = 0; i < n - 1; i++) {
        c = between(c, b);
        result.add(c);
      }
      return result;
    }
    if (a == null) {
      var c = between(a, b);
      final result = [c];
      for (var i = 0; i < n - 1; i++) {
        c = between(a, c);
        result.add(c);
      }
      return result.reversed.toList();
    }
    final mid = n ~/ 2;
    final c = between(a, b);
    return [...nBetween(a, c, mid), c, ...nBetween(c, b, n - mid - 1)];
  }

  /// Whether [key] is a valid fractional index key.
  static bool isValid(String key) {
    try {
      _validateKey(key);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  /// Orders entities by `(sortKey, id)` — the canonical row/column/sheet order.
  static int compare(String keyA, String idA, String keyB, String idB) {
    final c = keyA.compareTo(keyB);
    return c != 0 ? c : idA.compareTo(idB);
  }

  // ---------------------------------------------------------------------------

  static String _midpoint(String a, String? b) {
    if (b != null && a.compareTo(b) >= 0) throw ArgumentError('$a >= $b');
    if ((a.isNotEmpty && a[a.length - 1] == _zero) ||
        (b != null && b.isNotEmpty && b[b.length - 1] == _zero)) {
      throw ArgumentError('trailing zero');
    }
    if (b != null) {
      var n = 0;
      while ((n < a.length ? a[n] : _zero) == (n < b.length ? b[n] : null)) {
        n++;
      }
      if (n > 0) {
        return b.substring(0, n) +
            _midpoint(n < a.length ? a.substring(n) : '', b.substring(n));
      }
    }
    final digitA = a.isNotEmpty ? base62Value(a.codeUnitAt(0)) : 0;
    final digitB = b != null && b.isNotEmpty
        ? base62Value(b.codeUnitAt(0))
        : base62Digits.length;
    if (digitB - digitA > 1) {
      final midDigit = ((digitA + digitB) / 2).round();
      return base62Digits[midDigit];
    }
    if (b != null && b.length > 1) return b.substring(0, 1);
    return base62Digits[digitA] +
        _midpoint(a.isEmpty ? '' : a.substring(1), null);
  }

  static int _integerLength(String head) {
    final c = head.codeUnitAt(0);
    if (c >= 0x61 && c <= 0x7a) return c - 0x61 + 2;
    if (c >= 0x41 && c <= 0x5a) return 0x5a - c + 2;
    throw ArgumentError('Invalid order key head: $head');
  }

  static String _integerPart(String key) {
    if (key.isEmpty) throw ArgumentError('Empty order key');
    final len = _integerLength(key[0]);
    if (len > key.length) throw ArgumentError('Invalid order key: $key');
    return key.substring(0, len);
  }

  static void _validateKey(String key) {
    if (key == _smallestInteger) throw ArgumentError('Invalid order key: $key');
    final i = _integerPart(key);
    for (var k = 1; k < key.length; k++) {
      if (base62Value(key.codeUnitAt(k)) < 0) {
        throw ArgumentError('Invalid order key: $key');
      }
    }
    final f = key.substring(i.length);
    if (f.isNotEmpty && f[f.length - 1] == _zero) {
      throw ArgumentError('Invalid order key (trailing zero): $key');
    }
  }

  static String? _incrementInteger(String x) {
    final head = x[0];
    final digs = x.substring(1).split('');
    var carry = true;
    for (var i = digs.length - 1; carry && i >= 0; i--) {
      final d = base62Value(digs[i].codeUnitAt(0)) + 1;
      if (d == base62Digits.length) {
        digs[i] = _zero;
      } else {
        digs[i] = base62Digits[d];
        carry = false;
      }
    }
    if (carry) {
      if (head == 'Z') return 'a$_zero';
      if (head == 'z') return null;
      final h = String.fromCharCode(head.codeUnitAt(0) + 1);
      if (h.compareTo('a') > 0) {
        digs.add(_zero);
      } else {
        digs.removeLast();
      }
      return h + digs.join();
    }
    return head + digs.join();
  }

  static String? _decrementInteger(String x) {
    final head = x[0];
    final digs = x.substring(1).split('');
    var borrow = true;
    const last = 'z';
    for (var i = digs.length - 1; borrow && i >= 0; i--) {
      final d = base62Value(digs[i].codeUnitAt(0)) - 1;
      if (d == -1) {
        digs[i] = last;
      } else {
        digs[i] = base62Digits[d];
        borrow = false;
      }
    }
    if (borrow) {
      if (head == 'a') return 'Z$last';
      if (head == 'A') return null;
      final h = String.fromCharCode(head.codeUnitAt(0) - 1);
      if (h.compareTo('Z') < 0) {
        digs.add(last);
      } else {
        digs.removeLast();
      }
      return h + digs.join();
    }
    return head + digs.join();
  }
}
