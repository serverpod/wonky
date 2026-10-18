import '../addressing/base62_uuid.dart';
import '../formula/codec/ref_token.dart';

/// Token-level helpers over stored formulas (`=…⟦R:…;C:…⟧…`), independent of
/// the parser: id remapping (copy sheet, copy spreadsheet), id detection.
abstract final class StoredFormula {
  /// Whether [text] contains any reference token.
  static bool hasTokens(String text) => text.contains(RefToken.open);

  /// Applies [map] to every reference token outside string literals. Tokens
  /// that fail to decode are kept verbatim.
  static String mapTokens(String text, RefToken Function(RefToken token) map) {
    if (!hasTokens(text)) return text;
    final out = StringBuffer();
    var i = 0;
    final n = text.length;
    while (i < n) {
      final c = text.codeUnitAt(i);
      if (c == 0x22) {
        // String literal with "" escapes.
        final start = i;
        i++;
        while (i < n) {
          if (text.codeUnitAt(i) == 0x22) {
            if (i + 1 < n && text.codeUnitAt(i + 1) == 0x22) {
              i += 2;
              continue;
            }
            i++;
            break;
          }
          i++;
        }
        out.write(text.substring(start, i));
        continue;
      }
      if (c == RefToken.openCode) {
        final close = text.indexOf(RefToken.close, i + 1);
        if (close < 0) {
          out.write(text.substring(i));
          break;
        }
        final body = text.substring(i + 1, close);
        final tok = RefToken.decodeBody(body);
        if (tok == null) {
          out.write(text.substring(i, close + 1));
        } else {
          out.write(map(tok).encode());
        }
        i = close + 1;
        continue;
      }
      out.writeCharCode(c);
      i++;
    }
    return out.toString();
  }

  /// All reference tokens outside string literals.
  static List<RefToken> tokens(String text) {
    final list = <RefToken>[];
    mapTokens(text, (t) {
      list.add(t);
      return t;
    });
    return list;
  }

  /// Replaces sheet/row/column ids per [idMap] (ids not in the map are kept).
  /// Same-sheet tokens (no `S:`) can be pointed at [sameSheetTo] by adding an
  /// explicit `S:` field when the formula moves to a different sheet.
  static String remapIds(String text, Map<String, String> idMap) => mapTokens(
    text,
    (t) => t.copyWith(
      sheetId: t.sheetId == null ? null : (idMap[t.sheetId!] ?? t.sheetId),
      rowId: t.rowId == null ? null : (idMap[t.rowId!] ?? t.rowId),
      colId: t.colId == null ? null : (idMap[t.colId!] ?? t.colId),
    ),
  );

  /// Whether [text] might reference one of [ids] (fast substring prefilter on
  /// the token-encoded ids; may return true for false positives).
  static bool mayReference(String text, Iterable<String> ids) {
    if (!hasTokens(text)) return false;
    return referencesAny(text, idTokens(ids));
  }

  /// The ids as written in reference tokens (for [referencesAny]); compute once per
  /// batch of formulas.
  static Set<String> idTokens(Iterable<String> ids) => {
    for (final id in ids) Base62Uuid.toToken(id),
  };

  /// Whether a reference token in [text] has a sheet, row or column field whose
  /// encoded id is in [tokens] (from [idTokens]). Every reference a rewrite of
  /// those ids would change is found; it costs one pass over [text] whatever the
  /// number of ids (structural edits scan every formula of the workbook).
  static bool referencesAny(String text, Set<String> tokens) {
    if (tokens.isEmpty) return false;
    // Few ids (the usual edit): compare in place instead of hashing substrings.
    final few = tokens.length <= 8;
    var i = text.indexOf(RefToken.open);
    while (i >= 0) {
      final close = text.indexOf(RefToken.close, i + 1);
      if (close < 0) return false;
      // Fields `S:`/`R:`/`C:` separated by `;`.
      var f = i + 1;
      while (f < close) {
        var end = text.indexOf(';', f);
        if (end < 0 || end > close) end = close;
        if (end - f > 2 && text.codeUnitAt(f + 1) == 0x3a) {
          final k = text.codeUnitAt(f);
          if (k == 0x52 || k == 0x43 || k == 0x53) {
            if (few) {
              final length = end - f - 2;
              for (final t in tokens) {
                if (t.length == length && text.startsWith(t, f + 2)) {
                  return true;
                }
              }
            } else if (tokens.contains(text.substring(f + 2, end))) {
              return true;
            }
          }
        }
        f = end + 1;
      }
      i = text.indexOf(RefToken.open, close + 1);
    }
    return false;
  }

  /// Applies [f] to every string value starting with `=` inside a decoded JSON
  /// structure (CF `ruleJson`, DV `criteriaJson`, filter criteria, pivot
  /// specs). Returns the new structure and whether anything changed.
  static (Object?, bool) mapJsonFormulas(
    Object? json,
    String? Function(String formula) f,
  ) {
    var changed = false;
    Object? walk(Object? v) {
      if (v is String) {
        if (v.startsWith('=')) {
          final r = f(v);
          if (r != null && r != v) {
            changed = true;
            return r;
          }
        }
        return v;
      }
      if (v is List) return [for (final e in v) walk(e)];
      if (v is Map) return {for (final e in v.entries) e.key: walk(e.value)};
      return v;
    }

    final out = walk(json);
    return (out, changed);
  }
}
