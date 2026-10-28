part of 'hunspell.dart';

/// Position of a part inside a compound word.
enum _Pos { begin, middle, end }

/// Per-check state.
final class _Ctx {
  _Ctx({required this.forSuggest});

  /// Suggestion validation: NOSUGGEST words are not accepted.
  final bool forSuggest;

  /// The word being looked up is a case variant of the input (KEEPCASE).
  bool caseChanged = false;

  /// Reject compounds whose last part has FORCEUCASE (lowercase input).
  bool forceUcase = false;

  /// Work counter bounding pathological compound searches.
  int ops = 0;

  bool? compoundRepBad;
}

/// A dictionary form that matched: root flags plus the affixes used.
final class _Hit {
  _Hit(this.flags, this.pfx, this.sfx, this.sfx2);

  final _FlagSet flags;
  final _Affix? pfx;

  /// Suffix attached to the root.
  final _Affix? sfx;

  /// Outer suffix of a twofold suffix form.
  final _Affix? sfx2;

  bool has(int f) =>
      f != 0 &&
      (flags.contains(f) ||
          (pfx?.cont.contains(f) ?? false) ||
          (sfx?.cont.contains(f) ?? false) ||
          (sfx2?.cont.contains(f) ?? false));
}

const int _maxCompoundOps = 3000;
const int _maxBreakDepth = 8;

final RegExp _numberPattern = RegExp(r'^[+\-−]?\d+(?:[.,:\-]\d+)*\.?$');

/// Checks spelling against a [HunspellDictionary] plus personal words, and
/// produces suggestions.
///
/// Case rules follow Hunspell: a lowercase dictionary word also accepts its
/// Titlecase and ALL-CAPS forms, a Titlecase word its ALL-CAPS form, and
/// `KEEPCASE` words only their dictionary form.
final class SpellChecker {
  /// Creates a checker for [dictionary], with optional [personalWords]
  /// (accepted like dictionary words without affix flags).
  SpellChecker(this.dictionary, {Iterable<String> personalWords = const []}) {
    for (final w in personalWords) {
      addPersonalWord(w);
    }
  }

  /// The dictionary this checker uses.
  final HunspellDictionary dictionary;

  final Set<String> _personal = {};
  final Set<String> _personalNorm = {};

  /// The personal words, as added (read-only view).
  Set<String> get personalWords => UnmodifiableSetView(_personal);

  /// Accepts [word] (trimmed) from now on, including its Titlecase and
  /// ALL-CAPS forms when it is lowercase.
  void addPersonalWord(String word) {
    final w = word.trim();
    if (w.isEmpty) return;
    if (_personal.add(w)) _personalNorm.add(dictionary._normalize(w));
  }

  /// Removes [word] from the personal words.
  void removePersonalWord(String word) {
    if (!_personal.remove(word.trim())) return;
    _personalNorm
      ..clear()
      ..addAll(_personal.map(dictionary._normalize));
  }

  /// Whether [word] is correctly spelled.
  ///
  /// Besides plain dictionary lookup this applies `ICONV`/`IGNORE`, treats
  /// ’ and ' alike, accepts numbers, accepts a trailing period when the word
  /// (or the abbreviation with the period) is valid, rejects
  /// `FORBIDDENWORD`s, honours `NEEDAFFIX`, `ONLYINCOMPOUND`, `KEEPCASE`,
  /// affix rules and compounding, and accepts words split by `BREAK`
  /// patterns (by default `-`) when every part is correct.
  bool check(String word) => _check(word, forSuggest: false, compound: true);

  /// Checks a token from `SpellTokenizer`, also trying the abbreviation
  /// with its trailing period (`etc.`) when the token is followed by one.
  bool checkToken(SpellToken token) =>
      check(token.word) || (token.followedByPeriod && check('${token.word}.'));

  /// Up to [max] suggestions for [word], best first.
  ///
  /// Never contains [word] itself, preserves its capitalization pattern
  /// (`Teh` → `The`, `TEH` → `THE`) and never offers `FORBIDDENWORD` or
  /// `NOSUGGEST` words. Work stops once [budget] has elapsed on [stopwatch]
  /// (a new, started one by default); with an unlimited budget the result
  /// is deterministic.
  List<String> suggest(
    String word, {
    int max = 5,
    Duration budget = const Duration(milliseconds: 50),
    Stopwatch? stopwatch,
  }) {
    if (max <= 0 || word.trim().isEmpty) return const [];
    final sw = stopwatch ?? (Stopwatch()..start());
    return _Suggester(this, sw, budget.inMicroseconds).run(word, max);
  }

  // ------------------------------------------------------------ internals

  bool _check(String word, {required bool forSuggest, required bool compound}) {
    if (word.isEmpty) return true;
    final w = dictionary._normalize(word);
    if (w.isEmpty) return true;
    if (_personalNorm.contains(w)) return true;
    if (forSuggest) {
      // Suggestion candidates must be dictionary forms: no number, trailing
      // period or BREAK leniency (Hunspell's checkword).
      if (_isForbidden(w)) return false;
      if (_checkCased(w, true, compound)) return true;
      if (!w.contains("'")) return false;
      final alt = w.replaceAll("'", '’');
      return !_isForbidden(alt) && _checkCased(alt, true, compound);
    }
    if (_numberPattern.hasMatch(w)) return true;
    if (!dictionary._hasLettersOf(w)) return true;
    if (_checkDots(w, forSuggest, compound)) return true;
    if (w.contains("'")) {
      return _checkDots(w.replaceAll("'", '’'), forSuggest, compound);
    }
    return false;
  }

  bool _checkDots(String w, bool forSuggest, bool compound) {
    var end = w.length;
    while (end > 0 && w.codeUnitAt(end - 1) == 0x2E) {
      end--;
    }
    if (end == 0) return true;
    final base = end == w.length ? w : w.substring(0, end);
    if (_checkWhole(base, forSuggest, compound)) return true;
    return end < w.length && _checkWhole('$base.', forSuggest, compound);
  }

  bool _checkWhole(String w, bool forSuggest, bool compound) {
    if (_isForbidden(w)) return false;
    if (_checkCased(w, forSuggest, compound)) return true;
    if (dictionary._breaks.isEmpty) return false;
    return _checkBreak(w, 0, forSuggest, compound);
  }

  bool _isForbidden(String w) {
    final d = dictionary;
    if (d._forbidden == 0) return false;
    final e = d._words[w];
    if (e == null) return false;
    if (e is _FlagSet) return e.contains(d._forbidden);
    return (e as List<_FlagSet>).any((f) => f.contains(d._forbidden));
  }

  bool _checkCased(String w, bool forSuggest, bool compound) {
    final d = dictionary;
    final ctx = _Ctx(forSuggest: forSuggest);
    if (_forms(w, null, ctx, null)) return true;
    final cap = _capType(w);
    String? v2;
    String? v3;
    String? v4;
    switch (cap) {
      case _Cap.init:
        v2 = w.toLowerCase();
      case _Cap.all:
        v2 = w.toLowerCase();
        v3 = _initCap(w);
        if (w.contains("'") || w.contains('’')) v4 = _apostropheCap(w);
      case _Cap.lower || _Cap.huh || _Cap.huhInit:
        break;
    }
    final variants = [
      for (final v in [v2, v3, v4])
        if (v != null && v != w) v,
    ];
    ctx.caseChanged = true;
    for (final v in variants) {
      if (_personalNorm.contains(v)) return true;
      if (_isForbidden(v)) return false;
      if (_forms(v, null, ctx, null)) return true;
    }
    if (!compound || !d.hasCompounding) return false;
    ctx.caseChanged = false;
    ctx.forceUcase =
        d._forceUcase != 0 && (cap == _Cap.lower || cap == _Cap.huh);
    if (_compound(w, ctx)) return true;
    ctx.forceUcase = false;
    ctx.caseChanged = true;
    for (final v in variants) {
      if (_compound(v, ctx)) return true;
    }
    return false;
  }

  bool _checkBreak(String w, int depth, bool forSuggest, bool compound) {
    if (depth >= _maxBreakDepth) return false;
    for (final b in dictionary._breaks) {
      if (b.length > 1 && b.startsWith('^')) {
        final p = b.substring(1);
        if (w.length > p.length &&
            w.startsWith(p) &&
            _checkPart(w.substring(p.length), depth, forSuggest, compound)) {
          return true;
        }
        continue;
      }
      if (b.length > 1 && b.endsWith(r'$')) {
        final p = b.substring(0, b.length - 1);
        if (w.length > p.length &&
            w.endsWith(p) &&
            _checkPart(
              w.substring(0, w.length - p.length),
              depth,
              forSuggest,
              compound,
            )) {
          return true;
        }
        continue;
      }
      var i = w.indexOf(b, 1);
      while (i > 0 && i + b.length < w.length) {
        if (_checkPart(w.substring(0, i), depth, forSuggest, compound) &&
            _checkPart(
              w.substring(i + b.length),
              depth,
              forSuggest,
              compound,
            )) {
          return true;
        }
        i = w.indexOf(b, i + 1);
      }
    }
    return false;
  }

  bool _checkPart(String p, int depth, bool forSuggest, bool compound) =>
      p.isNotEmpty &&
      !_isForbidden(p) &&
      (_personalNorm.contains(p) ||
          _checkCased(p, forSuggest, compound) ||
          _checkBreak(p, depth + 1, forSuggest, compound));

  // ------------------------------------------------------- affix forms

  /// Tries every way to read [w] as root + affixes. For each valid form,
  /// [onHit] decides whether to stop (true); without it, the first valid
  /// form wins.
  bool _forms(String w, _Pos? pos, _Ctx ctx, bool Function(_Hit)? onHit) {
    final d = dictionary;
    if (_tryRoot(w, null, null, null, pos, ctx, onHit)) return true;
    final len = w.length;
    final minRest = d._fullStrip ? 0 : 1;
    final maxS = math.min(d._maxSuffixLen, len - minRest);
    for (var k = 0; k <= maxS; k++) {
      final list = d._suffixes[k == 0 ? '' : w.substring(len - k)];
      if (list == null) continue;
      final head = k == 0 ? w : w.substring(0, len - k);
      for (final s in list) {
        final stem = s.strip.isEmpty ? head : head + s.strip;
        if (stem.isEmpty || !s.cond.matchesEnd(stem)) continue;
        if (_tryRoot(stem, null, s, null, pos, ctx, onHit)) return true;
        if (d._twofoldFlags.contains(s.flag) &&
            _innerSuffix(stem, s, null, pos, ctx, onHit)) {
          return true;
        }
      }
    }
    final maxP = math.min(d._maxPrefixLen, len - minRest);
    for (var k = 0; k <= maxP; k++) {
      final list = d._prefixes[k == 0 ? '' : w.substring(0, k)];
      if (list == null) continue;
      final tail = k == 0 ? w : w.substring(k);
      for (final p in list) {
        final stem = p.strip.isEmpty ? tail : p.strip + tail;
        if (stem.isEmpty || !p.cond.matchesStart(stem)) continue;
        if (_tryRoot(stem, p, null, null, pos, ctx, onHit)) return true;
        if (p.cross &&
            d._hasCrossSuffix &&
            _suffixAfterPrefix(stem, p, pos, ctx, onHit)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _suffixAfterPrefix(
    String w,
    _Affix p,
    _Pos? pos,
    _Ctx ctx,
    bool Function(_Hit)? onHit,
  ) {
    final d = dictionary;
    final len = w.length;
    final maxS = math.min(d._maxSuffixLen, len - (d._fullStrip ? 0 : 1));
    for (var k = 0; k <= maxS; k++) {
      final list = d._suffixes[k == 0 ? '' : w.substring(len - k)];
      if (list == null) continue;
      final head = k == 0 ? w : w.substring(0, len - k);
      for (final s in list) {
        if (!s.cross) continue;
        final stem = s.strip.isEmpty ? head : head + s.strip;
        if (stem.isEmpty || !s.cond.matchesEnd(stem)) continue;
        if (_tryRoot(stem, p, s, null, pos, ctx, onHit)) return true;
        if (d._twofoldFlags.contains(s.flag) &&
            _innerSuffix(stem, s, p, pos, ctx, onHit)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Twofold suffixes: [w] = root + inner suffix, where the inner suffix's
  /// continuation class allows [outer].
  bool _innerSuffix(
    String w,
    _Affix outer,
    _Affix? p,
    _Pos? pos,
    _Ctx ctx,
    bool Function(_Hit)? onHit,
  ) {
    final d = dictionary;
    final len = w.length;
    final maxS = math.min(d._maxSuffixLen, len - (d._fullStrip ? 0 : 1));
    for (var k = 0; k <= maxS; k++) {
      final list = d._suffixes[k == 0 ? '' : w.substring(len - k)];
      if (list == null) continue;
      final head = k == 0 ? w : w.substring(0, len - k);
      for (final s in list) {
        if (!s.cont.contains(outer.flag)) continue;
        if (p != null && !s.cross) continue;
        final stem = s.strip.isEmpty ? head : head + s.strip;
        if (stem.isEmpty || !s.cond.matchesEnd(stem)) continue;
        if (_tryRoot(stem, p, s, outer, pos, ctx, onHit)) return true;
      }
    }
    return false;
  }

  bool _tryRoot(
    String root,
    _Affix? p,
    _Affix? s,
    _Affix? s2,
    _Pos? pos,
    _Ctx ctx,
    bool Function(_Hit)? onHit,
  ) {
    final e = dictionary._words[root];
    if (e == null) return false;
    if (e is _FlagSet) return _accept(e, p, s, s2, pos, ctx, onHit);
    for (final f in e as List<_FlagSet>) {
      if (_accept(f, p, s, s2, pos, ctx, onHit)) return true;
    }
    return false;
  }

  bool _accept(
    _FlagSet f,
    _Affix? p,
    _Affix? s,
    _Affix? s2,
    _Pos? pos,
    _Ctx ctx,
    bool Function(_Hit)? onHit,
  ) {
    if (!_good(f, p, s, s2, pos, ctx)) return false;
    return onHit == null || onHit(_Hit(f, p, s, s2));
  }

  /// Hunspell's rules for whether root [f] with the given affixes is a
  /// valid (compound part) form.
  bool _good(
    _FlagSet f,
    _Affix? p,
    _Affix? s,
    _Affix? s2,
    _Pos? pos,
    _Ctx ctx,
  ) {
    final d = dictionary;
    if (f.contains(d._forbidden)) return false;
    if (ctx.forSuggest && f.contains(d._noSuggest)) return false;
    if (ctx.caseChanged && f.contains(d._keepCase)) return false;
    if (s != null &&
        !(f.contains(s.flag) || (p != null && p.cont.contains(s.flag)))) {
      return false;
    }
    if (p != null &&
        !(f.contains(p.flag) ||
            (s != null && s.cont.contains(p.flag)) ||
            (s2 != null && s2.cont.contains(p.flag)))) {
      return false;
    }
    final na = d._needAffix;
    if (na != 0) {
      if (p == null && s == null) {
        if (f.contains(na)) return false;
      } else if ((p == null || p.cont.contains(na)) &&
          (s == null || s.cont.contains(na)) &&
          (s2 == null || s2.cont.contains(na))) {
        return false;
      }
    }
    final cf = d._circumfix;
    if (cf != 0) {
      final pc = p != null && p.cont.contains(cf);
      final sc =
          (s != null && s.cont.contains(cf)) ||
          (s2 != null && s2.cont.contains(cf));
      if (pc != sc) return false;
    }
    bool has(int flag) =>
        flag != 0 &&
        (f.contains(flag) ||
            (p?.cont.contains(flag) ?? false) ||
            (s?.cont.contains(flag) ?? false) ||
            (s2?.cont.contains(flag) ?? false));
    if (pos == null) {
      return !has(d._onlyInCompound);
    }
    if (has(d._compoundForbid)) return false;
    final allowed =
        has(d._compoundFlag) ||
        switch (pos) {
          _Pos.begin => has(d._compoundBegin),
          _Pos.middle => has(d._compoundMiddle),
          _Pos.end => has(d._compoundLast),
        };
    if (!allowed) return false;
    final permit = d._compoundPermit;
    if (p != null && pos != _Pos.begin && !p.cont.contains(permit)) {
      return false;
    }
    final outer = s2 ?? s;
    if (outer != null && pos != _Pos.end && !outer.cont.contains(permit)) {
      return false;
    }
    if (pos == _Pos.end && ctx.forceUcase && has(d._forceUcase)) return false;
    return true;
  }

  // ---------------------------------------------------------- compounds

  bool _compound(String w, _Ctx ctx) {
    final d = dictionary;
    if (w.length < 2 * d._compoundMin) return false;
    ctx.compoundRepBad = null;
    if (d._hasCompoundFlags) {
      ctx.ops = 0;
      if (_compoundByFlags(w, 0, 0, null, null, ctx)) return true;
    }
    if (d._rules.isNotEmpty) {
      ctx.ops = 0;
      if (_compoundByRules(w, 0, <_FlagSet>[], d._rules, ctx)) return true;
    }
    return false;
  }

  bool _compoundByFlags(
    String w,
    int start,
    int depth,
    String? prevText,
    _Hit? prevHit,
    _Ctx ctx,
  ) {
    if (++ctx.ops > _maxCompoundOps) return false;
    final d = dictionary;
    final rest = start == 0 ? w : w.substring(start);
    if (depth > 0 &&
        rest.length >= d._compoundMin &&
        _forms(
          rest,
          _Pos.end,
          ctx,
          (hit) =>
              _boundaryOk(prevText!, prevHit!, rest, hit) &&
              !_compoundRepBad(w, ctx),
        )) {
      return true;
    }
    final min = d._compoundMin;
    if (rest.length < 2 * min) return false;
    if (d._compoundWordMax > 0 && depth + 2 > d._compoundWordMax) return false;
    final pos = depth == 0 ? _Pos.begin : _Pos.middle;
    for (var i = min; i <= rest.length - min; i++) {
      final part = rest.substring(0, i);
      final found = _forms(
        part,
        pos,
        ctx,
        (hit) =>
            (prevText == null || _boundaryOk(prevText, prevHit!, part, hit)) &&
            _compoundByFlags(w, start + i, depth + 1, part, hit, ctx),
      );
      if (found) return true;
      if (ctx.ops > _maxCompoundOps) return false;
    }
    return false;
  }

  bool _boundaryOk(String left, _Hit lh, String right, _Hit rh) {
    final d = dictionary;
    if (d._checkCompoundDup && left == right) return false;
    if (d._checkCompoundTriple) {
      final ll = left.length;
      final last = left.codeUnitAt(ll - 1);
      final first = right.codeUnitAt(0);
      if (ll >= 2 && left.codeUnitAt(ll - 2) == last && last == first) {
        return false;
      }
      if (right.length >= 2 && last == first && right.codeUnitAt(1) == first) {
        return false;
      }
    }
    if (d._checkCompoundCase) {
      final l = left.codeUnitAt(left.length - 1);
      final r = right.codeUnitAt(0);
      if (l != 0x2D && r != 0x2D && (_isUpperUnit(l) || _isUpperUnit(r))) {
        return false;
      }
    }
    for (final pt in d._compoundPatterns) {
      if ((pt.end.isEmpty || left.endsWith(pt.end)) &&
          (pt.begin.isEmpty || right.startsWith(pt.begin)) &&
          (pt.endFlag == 0 || lh.has(pt.endFlag)) &&
          (pt.beginFlag == 0 || rh.has(pt.beginFlag))) {
        return false;
      }
    }
    return true;
  }

  /// CHECKCOMPOUNDREP: a compound is wrong when a REP replacement turns it
  /// into a dictionary word.
  bool _compoundRepBad(String w, _Ctx ctx) {
    final cached = ctx.compoundRepBad;
    if (cached != null) return cached;
    var bad = false;
    final d = dictionary;
    if (d._checkCompoundRep) {
      final plain = _Ctx(forSuggest: false);
      outer:
      for (final rep in d._reps) {
        if (rep.from.isEmpty) continue;
        var i = w.indexOf(rep.from);
        while (i >= 0) {
          final cand =
              w.substring(0, i) + rep.to + w.substring(i + rep.from.length);
          if (_forms(cand, null, plain, null)) {
            bad = true;
            break outer;
          }
          i = w.indexOf(rep.from, i + 1);
        }
      }
    }
    ctx.compoundRepBad = bad;
    return bad;
  }

  bool _compoundByRules(
    String w,
    int start,
    List<_FlagSet> parts,
    List<_CompoundRule> rules,
    _Ctx ctx,
  ) {
    if (++ctx.ops > _maxCompoundOps) return false;
    final d = dictionary;
    final rest = start == 0 ? w : w.substring(start);
    if (parts.isNotEmpty) {
      for (final f in _homonyms(rest)) {
        if (!_ruleUsable(f, ctx)) continue;
        parts.add(f);
        final ok = rules.any((r) => r.matches(parts, partial: false));
        parts.removeLast();
        if (ok) return true;
      }
    }
    final min = d._compoundMin;
    if (rest.length < 2 * min) return false;
    if (d._compoundWordMax > 0 && parts.length + 2 > d._compoundWordMax) {
      return false;
    }
    for (var i = min; i <= rest.length - min; i++) {
      for (final f in _homonyms(rest.substring(0, i))) {
        if (!_ruleUsable(f, ctx)) continue;
        parts.add(f);
        final sub = [
          for (final r in rules)
            if (r.matches(parts, partial: true)) r,
        ];
        final ok =
            sub.isNotEmpty && _compoundByRules(w, start + i, parts, sub, ctx);
        parts.removeLast();
        if (ok) return true;
      }
    }
    return false;
  }

  bool _ruleUsable(_FlagSet f, _Ctx ctx) {
    final d = dictionary;
    if (f.contains(d._forbidden)) return false;
    if (ctx.forSuggest && f.contains(d._noSuggest)) return false;
    return f.containsAny(d._ruleFlags);
  }

  List<_FlagSet> _homonyms(String w) {
    final e = dictionary._words[w];
    if (e == null) return const [];
    if (e is _FlagSet) return [e];
    return e as List<_FlagSet>;
  }
}
