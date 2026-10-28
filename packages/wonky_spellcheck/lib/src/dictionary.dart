part of 'hunspell.dart';

/// A parsed Hunspell dictionary: the affix rules of an `.aff` file and the
/// word list of a `.dic` file.
///
/// Both files must already be decoded to Dart strings (the shipped
/// dictionaries are UTF-8; the `SET` directive is parsed but informational).
/// Use [HunspellDictionary.parse] for a synchronous parse (tests, server) or
/// [HunspellDictionaryLoader] to parse in time slices on the UI thread.
final class HunspellDictionary {
  HunspellDictionary._();

  /// Parses [aff] and [dic] synchronously.
  factory HunspellDictionary.parse(String aff, String dic) {
    final parser = _Parser(aff, dic);
    parser.run(null);
    return parser.dictionary;
  }

  final _Flags _flags = _Flags();

  /// Word → `_FlagSet` or `List<_FlagSet>` (homonyms).
  final _WordMap _words = _WordMap();

  String _encoding = 'UTF-8';
  String? _language;
  String _try = '';
  String _wordChars = '';
  String _key = 'qwertyuiop|asdfghjkl|zxcvbnm';
  String _ignore = '';
  final _Conv _iconv = _Conv();
  final _Conv _oconv = _Conv();
  final List<_Rep> _reps = [];
  final List<List<String>> _maps = [];
  List<String> _breaks = const ['-', '^-', r'-$'];

  // Affix tables, indexed by appended string and by flag.
  final Map<String, List<_Affix>> _prefixes = {};
  final Map<String, List<_Affix>> _suffixes = {};
  final Map<int, List<_Affix>> _prefixesByFlag = {};
  final Map<int, List<_Affix>> _suffixesByFlag = {};
  int _maxPrefixLen = 0;
  int _maxSuffixLen = 0;

  /// Flags of suffixes that appear in another suffix's continuation class.
  final Set<int> _twofoldFlags = {};
  bool _hasCrossSuffix = false;

  // Special flags (0 = not set).
  int _needAffix = 0;
  int _forbidden = 0;
  int _keepCase = 0;
  int _noSuggest = 0;
  int _onlyInCompound = 0;
  int _circumfix = 0;
  int _compoundFlag = 0;
  int _compoundBegin = 0;
  int _compoundMiddle = 0;
  int _compoundLast = 0;
  int _compoundPermit = 0;
  int _compoundForbid = 0;
  int _forceUcase = 0;

  int _compoundMin = 3;
  int _compoundWordMax = 0;
  final List<_CompoundRule> _rules = [];
  final Set<int> _ruleFlags = {};
  bool _checkCompoundDup = false;
  bool _checkCompoundTriple = false;
  bool _checkCompoundCase = false;
  bool _checkCompoundRep = false;
  final List<_CompoundPattern> _compoundPatterns = [];

  bool _noSplitSugs = false;
  bool _fullStrip = false;
  int _maxNgramSugs = 4;
  int _maxCompoundSugs = 3;

  // Lazily built suggestion helpers.
  List<String>? _rootList;
  Set<int>? _alphabet;
  String? _effectiveTry;
  Map<int, String>? _keyNeighbours;

  /// The `TRY` characters (suggestion alphabet, most frequent first).
  String get tryChars => _try;

  /// Extra word characters (`WORDCHARS`) to pass to `SpellTokenizer`.
  String get wordChars => _wordChars;

  /// Keyboard rows for adjacent-key suggestions (`KEY`).
  String get keyboard => _key;

  /// The `SET` encoding name as declared in the `.aff` file.
  String get encoding => _encoding;

  /// The `LANG` directive, if any.
  String? get language => _language;

  /// Number of distinct dictionary words (roots).
  int get wordCount => _words.length;

  /// Whether the dictionary uses compounding (`COMPOUNDFLAG`,
  /// `COMPOUNDBEGIN`/`COMPOUNDLAST` or `COMPOUNDRULE`).
  bool get hasCompounding => _hasCompoundFlags || _rules.isNotEmpty;

  /// Whether [word] is a root of the `.dic` file (exact, no affixes).
  bool containsRoot(String word) => _words.containsKey(word);

  bool get _hasCompoundFlags =>
      _compoundFlag != 0 || (_compoundBegin != 0 && _compoundLast != 0);

  /// ICONV, IGNORE and built-in apostrophe normalization (’ → ').
  String _normalize(String w) {
    var s = _iconv.apply(w);
    if (_ignore.isNotEmpty) s = _removeChars(s, _ignore);
    if (s.contains('’')) s = s.replaceAll('’', "'");
    return s;
  }

  void _addWord(String word, _FlagSet flags) {
    final existing = _words[word];
    if (existing == null) {
      _words[word] = flags;
    } else if (existing is _FlagSet) {
      if (!identical(existing, flags)) {
        _words[word] = <_FlagSet>[existing, flags];
      }
    } else {
      final list = existing as List<_FlagSet>;
      if (!list.any((f) => identical(f, flags))) list.add(flags);
    }
  }

  List<String> get _roots => _rootList ??= _words.keys.toList(growable: false);

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);

  /// Whether [word] has a letter of this dictionary's alphabet (the letters
  /// of its words and `TRY`, in either case). A word in another script
  /// (Arabic in an English document) has none: it is not checked.
  bool _hasLettersOf(String word) {
    final alphabet = _alphabet ??= _buildAlphabet();
    // An empty dictionary knows no script: it checks (rejects) everything.
    if (alphabet.isEmpty) return true;
    for (final m in _letter.allMatches(word)) {
      if (alphabet.contains(m[0]!.runes.first)) return true;
    }
    return false;
  }

  Set<int> _buildAlphabet() {
    final letters = <String>{};
    for (final w in [_try, ..._words.keys]) {
      for (final m in _letter.allMatches(w)) {
        letters.add(m[0]!);
      }
    }
    return {
      for (final l in letters) ...[
        l.runes.first,
        ...l.toLowerCase().runes,
        ...l.toUpperCase().runes,
      ],
    };
  }

  /// TRY, or (when the `.aff` has none) the dictionary's letters by
  /// frequency.
  String get _tryForSuggest {
    final cached = _effectiveTry;
    if (cached != null) return cached;
    if (_try.isNotEmpty) return _effectiveTry = _try;
    final counts = <int, int>{};
    var n = 0;
    for (final w in _words.keys) {
      for (final c in w.codeUnits) {
        if (!_isNeutralUnit(c)) counts[c] = (counts[c] ?? 0) + 1;
      }
      if (++n > 20000) break;
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return _effectiveTry = String.fromCharCodes(sorted.take(60));
  }

  /// Character → keyboard neighbours from [keyboard] (`|`-separated rows).
  Map<int, String> get _neighbours {
    final cached = _keyNeighbours;
    if (cached != null) return cached;
    final map = <int, StringBuffer>{};
    for (final row in _key.split('|')) {
      for (var i = 0; i < row.length; i++) {
        final sb = map.putIfAbsent(row.codeUnitAt(i), StringBuffer.new);
        if (i > 0) sb.writeCharCode(row.codeUnitAt(i - 1));
        if (i + 1 < row.length) sb.writeCharCode(row.codeUnitAt(i + 1));
      }
    }
    return _keyNeighbours = {
      for (final e in map.entries) e.key: e.value.toString(),
    };
  }
}

/// Parses a [HunspellDictionary] incrementally, so a large `.dic` can be
/// loaded on the UI thread in small time slices (e.g. 8 ms per frame).
///
/// ```dart
/// final loader = HunspellDictionaryLoader(aff, dic);
/// while (!loader.step(const Duration(milliseconds: 8))) {
///   await nextIdleSlot();
/// }
/// final dictionary = loader.result;
/// ```
final class HunspellDictionaryLoader {
  /// Creates a loader for [aff] and [dic]; no work is done until [step].
  HunspellDictionaryLoader(String aff, String dic)
    : _parser = _Parser(aff, dic);

  final _Parser _parser;

  /// Parses for at most about [budget] (measured with a [Stopwatch] and
  /// checked every few hundred lines) and returns whether parsing is done.
  ///
  /// Every call makes progress, even with a zero budget.
  bool step(Duration budget) {
    if (_parser.done) return true;
    final sw = Stopwatch()..start();
    final limit = budget.inMicroseconds;
    return _parser.run(() => sw.elapsedMicroseconds >= limit);
  }

  /// Whether parsing has finished.
  bool get isDone => _parser.done;

  /// Fraction of the input parsed so far, from 0 to 1.
  double get progress => _parser.progress;

  /// The parsed dictionary. Throws a [StateError] until [step] returned
  /// true.
  HunspellDictionary get result {
    if (!_parser.done) {
      throw StateError('HunspellDictionaryLoader: parsing is not done yet');
    }
    return _parser.dictionary;
  }
}

/// Word → flags map, sharded so that no single rehash while loading a large
/// `.dic` takes long (keeps [HunspellDictionaryLoader.step] within budget).
final class _WordMap {
  static const int _shardCount = 32;

  final List<HashMap<String, Object>> _shards = List.generate(
    _shardCount,
    (_) => HashMap<String, Object>(),
    growable: false,
  );

  HashMap<String, Object> _shard(String w) =>
      _shards[w.hashCode & (_shardCount - 1)];

  Object? operator [](String w) => _shard(w)[w];

  void operator []=(String w, Object v) => _shard(w)[w] = v;

  bool containsKey(String w) => _shard(w).containsKey(w);

  int get length {
    var n = 0;
    for (final s in _shards) {
      n += s.length;
    }
    return n;
  }

  Iterable<String> get keys sync* {
    for (final s in _shards) {
      yield* s.keys;
    }
  }
}

String _removeChars(String s, String chars) {
  var hit = false;
  for (var i = 0; i < s.length && !hit; i++) {
    hit = chars.contains(s[i]);
  }
  if (!hit) return s;
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (!chars.contains(s[i])) sb.writeCharCode(s.codeUnitAt(i));
  }
  return sb.toString();
}
