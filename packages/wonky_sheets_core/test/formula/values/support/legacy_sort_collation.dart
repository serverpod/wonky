// Frozen copy of a removed implementation, kept as a test oracle (CQ-50).

/// The collation key `SORT()` used before CQ-50 (`Compare._collationKey`,
/// a small accent table and no cache). Kept unchanged as the oracle of
/// `collation_differential_test.dart`, which pinned the move of `SORT()` to
/// the shared [Collation] of Data › Sort.
String legacySortCollationKey(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    b.write(_stripMark[r] ?? String.fromCharCode(r));
  }
  return b.toString();
}

/// The characters the legacy table folds.
const legacyFoldedCharacters =
    'àáâãäåāăąçćčďèéêëēėęěìíîïīįłñńňòóôõöøōőŕřśšşťùúûüūůűųýÿźżžß';

final Map<int, String> _stripMark = () {
  const from = 'àáâãäåāăąçćčďèéêëēėęěìíîïīįłñńňòóôõöøōőŕřśšşťùúûüūůűųýÿźżžß';
  const to = [
    'a',
    'a',
    'a',
    'a',
    'a',
    'a',
    'a',
    'a',
    'a',
    'c',
    'c',
    'c',
    'd',
    'e',
    'e',
    'e',
    'e', //
    'e',
    'e',
    'e',
    'e',
    'i',
    'i',
    'i',
    'i',
    'i',
    'i',
    'l',
    'n',
    'n',
    'n',
    'o',
    'o',
    'o', //
    'o',
    'o',
    'o',
    'o',
    'o',
    'r',
    'r',
    's',
    's',
    's',
    't',
    'u',
    'u',
    'u',
    'u',
    'u',
    'u', //
    'u', 'u', 'y', 'y', 'z', 'z', 'z', 'ss',
  ];
  final m = <int, String>{};
  final runes = from.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    m[runes[i]] = to[i];
  }
  return m;
}();
