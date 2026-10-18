import 'package:wonky_numfmt/wonky_numfmt.dart';

import '../../eval/eval_context.dart';
import '../../parser/formula_locale.dart';
import '../../values/fvalue.dart';

/// The number-format language of TEXT(), TO_TEXT, DOLLAR, FIXED and QUERY
/// `format`: the cell display's engine (`wonky_numfmt`, 06 §5), so
/// `=TEXT(A1, "<A1's format>")` gives what A1 shows (CQ-50: one
/// implementation). Output is plain text: colors are dropped, `_c` becomes a
/// space and `*c` is omitted ([FormattedValue.plainText]).
///
/// Invalid patterns (and the internal `preset:*` ids) give null (TEXT()'s
/// `#VALUE!`); an empty pattern formats numbers as `""` and leaves text as
/// is; booleans are `TRUE`/`FALSE`; non-finite numbers give null.
final class NumberFormatTextFormatter implements NumberTextFormatter {
  /// Creates the formatter (over [NumberPatternFormatter.instance]).
  const NumberFormatTextFormatter();

  @override
  String? format(FValue value, String pattern, FormulaLocale locale) {
    if (value is FRich) value = value.scalar;
    final formatter = NumberPatternFormatter.instance;
    if (pattern.startsWith('preset:') || formatter.cache.ast(pattern) == null) {
      return null;
    }
    switch (value) {
      case FText(:final v):
        if (pattern.isEmpty) return v;
        return formatter.formatString(v, pattern, locale: locale.id).plainText;
      case FBool(:final v):
        return v ? 'TRUE' : 'FALSE';
      case FEmpty() || FOmitted():
        return _number(0, pattern, locale);
      case FNumber(:final v):
        if (!v.isFinite) return null;
        return _number(v, pattern, locale);
      default:
        return null;
    }
  }

  static String _number(double x, String pattern, FormulaLocale locale) {
    if (pattern.isEmpty) return '';
    return NumberPatternFormatter.instance
        .formatNumber(x, pattern, locale: locale.id)
        .plainText;
  }
}
