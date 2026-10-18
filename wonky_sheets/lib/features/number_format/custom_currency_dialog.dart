import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';
import 'mcp_dialog_state.dart';

/// A currency of the custom currency dialog: ISO code, symbol, English name.
typedef CurrencyInfo = ({String code, String symbol, String name});

/// Currencies offered by the custom currency dialog (04 §11.4).
const List<CurrencyInfo> customCurrencies = [
  (code: 'USD', symbol: r'$', name: 'US Dollar'),
  (code: 'EUR', symbol: '€', name: 'Euro'),
  (code: 'GBP', symbol: '£', name: 'British Pound'),
  (code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  (code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
  (code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  (code: 'KRW', symbol: '₩', name: 'South Korean Won'),
  (code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
  (code: 'CAD', symbol: r'CA$', name: 'Canadian Dollar'),
  (code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
  (code: 'NZD', symbol: r'NZ$', name: 'New Zealand Dollar'),
  (code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
  (code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
  (code: 'DKK', symbol: 'kr', name: 'Danish Krone'),
  (code: 'ISK', symbol: 'kr', name: 'Icelandic Króna'),
  (code: 'PLN', symbol: 'zł', name: 'Polish Złoty'),
  (code: 'CZK', symbol: 'Kč', name: 'Czech Koruna'),
  (code: 'HUF', symbol: 'Ft', name: 'Hungarian Forint'),
  (code: 'RON', symbol: 'lei', name: 'Romanian Leu'),
  (code: 'BGN', symbol: 'лв', name: 'Bulgarian Lev'),
  (code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
  (code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
  (code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia'),
  (code: 'ILS', symbol: '₪', name: 'Israeli New Shekel'),
  (code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
  (code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
  (code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
  (code: 'ZAR', symbol: 'R', name: 'South African Rand'),
  (code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
  (code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
  (code: 'BRL', symbol: r'R$', name: 'Brazilian Real'),
  (code: 'MXN', symbol: r'MX$', name: 'Mexican Peso'),
  (code: 'ARS', symbol: r'$', name: 'Argentine Peso'),
  (code: 'CLP', symbol: r'$', name: 'Chilean Peso'),
  (code: 'COP', symbol: r'$', name: 'Colombian Peso'),
  (code: 'PEN', symbol: 'S/', name: 'Peruvian Sol'),
  (code: 'HKD', symbol: r'HK$', name: 'Hong Kong Dollar'),
  (code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
  (code: 'TWD', symbol: r'NT$', name: 'New Taiwan Dollar'),
  (code: 'THB', symbol: '฿', name: 'Thai Baht'),
  (code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
  (code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
  (code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
  (code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  (code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
  (code: 'BTC', symbol: '₿', name: 'Bitcoin'),
];

/// The format variants of a currency (04 §11.4).
List<String> currencyVariants(CurrencyInfo c) {
  final s = '[\$${c.symbol}]';
  return [
    '$s#,##0.00',
    '$s#,##0',
    '$s#,##0.00;$s(#,##0.00)',
    '$s #,##0.00',
    '#,##0.00 $s',
    '[\$${c.code}] #,##0.00',
    '$s#,##0.00;[Red]-$s#,##0.00',
  ];
}

/// Custom currency (04 §11.4): searchable currencies, each expanding to
/// format variants with live examples. Returns the pattern.
Future<String?> showCustomCurrencyDialog(
  BuildContext context, {
  required String locale,
}) => showShadDialog<String>(
  context: context,
  builder: (_) => CustomCurrencyDialog(locale: locale),
);

class CustomCurrencyDialog extends StatefulWidget {
  const CustomCurrencyDialog({super.key, required this.locale});

  final String locale;

  @override
  State<CustomCurrencyDialog> createState() => _CustomCurrencyDialogState();
}

class _CustomCurrencyDialogState extends McpDialogState<CustomCurrencyDialog> {
  final _search = TextEditingController();
  String? _expanded;
  String? _pattern;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The currency's name in the UI language (English name as fallback).
  String _name(CurrencyInfo c) {
    final n = sheetsL10n(context).currencyName(c.code);
    return n == c.code ? c.name : n;
  }

  List<CurrencyInfo> get _matches {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return customCurrencies;
    return [
      for (final c in customCurrencies)
        if (c.code.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q) ||
            _name(c).toLowerCase().contains(q) ||
            c.symbol.toLowerCase() == q)
          c,
    ];
  }

  /// The `[Red]`/`[ColorN]` color of [pattern] for [v], if any.
  Color? _color(String pattern, double v) {
    final c = NumberFormatter.instance
        .format(NumberValue(v), pattern, locale: widget.locale)
        .colorArgb;
    return c == null ? null : Color(c);
  }

  String _ex(String pattern, double v) => NumberFormatter.instance.formatText(
    NumberValue(v),
    pattern,
    locale: widget.locale,
  );

  @override
  Map<String, Object?> describe() => {
    'title': 'Custom currency',
    'fields': [
      {
        'id': 'search',
        'label': 'Search',
        'type': 'text',
        'value': _search.text,
      },
      {
        'id': 'pattern',
        'label': 'Format',
        'type': 'select',
        'value': _pattern,
        'options': [for (final c in _matches.take(10)) ...currencyVariants(c)],
      },
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
      {'id': 'apply', 'label': 'Apply', 'enabled': _pattern != null},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    if (id == 'search' && value is String) {
      setState(() => _search.text = value);
      return true;
    }
    if (id == 'pattern' && value is String) {
      setState(() => _pattern = value);
      return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'cancel') {
      close();
      return true;
    }
    if (buttonId == 'apply' && _pattern != null) {
      close(_pattern);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final list = _matches;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => close(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.customCurrency'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.currencyDialogTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.customCurrency.cancel'),
            onPressed: () => close(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.customCurrency.apply'),
            enabled: _pattern != null,
            onPressed: () => close(_pattern),
            child: Text(l.dialogApply),
          ),
        ],
        child: SizedBox(
          width: 460,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadInput(
                key: const ValueKey<String>('dialog.customCurrency.search'),
                controller: _search,
                autofocus: true,
                placeholder: Text(l.currencySearch),
                leading: const Icon(LucideIcons.search, size: 16),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          l.currencyNoMatch,
                          style: theme.textTheme.muted,
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final c = list[i];
                          final open = _expanded == c.code || list.length == 1;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ShadButton.ghost(
                                key: ValueKey<String>(
                                  'dialog.customCurrency.${c.code}',
                                ),
                                width: double.infinity,
                                mainAxisAlignment: MainAxisAlignment.start,
                                leading: Icon(
                                  open
                                      ? LucideIcons.chevronDown
                                      : LucideIcons.chevronRight,
                                  size: 15,
                                ),
                                onPressed: () => setState(
                                  () => _expanded = open ? null : c.code,
                                ),
                                child: Expanded(
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        child: Text(
                                          c.code,
                                          textAlign: TextAlign.start,
                                          style: theme.textTheme.small.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 44,
                                        child: Text(
                                          c.symbol,
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _name(c),
                                          textAlign: TextAlign.start,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (open)
                                for (final p in currencyVariants(c))
                                  Padding(
                                    padding: const EdgeInsets.only(left: 28),
                                    child: _Variant(
                                      key: ValueKey<String>(
                                        'dialog.customCurrency.variant.$p',
                                      ),
                                      selected: _pattern == p,
                                      positive: _ex(p, 1000.12),
                                      negative: _ex(p, -1000.12),
                                      positiveColor: _color(p, 1000.12),
                                      negativeColor: _color(p, -1000.12),
                                      onPressed: () =>
                                          setState(() => _pattern = p),
                                      onDoubleTap: () => close(p),
                                    ),
                                  ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Variant extends StatelessWidget {
  const _Variant({
    super.key,
    required this.selected,
    required this.positive,
    required this.negative,
    required this.onPressed,
    required this.onDoubleTap,
    this.positiveColor,
    this.negativeColor,
  });

  /// Colors of the examples from `[Red]`-style sections.
  final Color? positiveColor;
  final Color? negativeColor;
  final bool selected;
  final String positive;
  final String negative;
  final VoidCallback onPressed;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Semantics(
        selected: selected,
        child: ShadButton.ghost(
          size: ShadButtonSize.sm,
          width: double.infinity,
          mainAxisAlignment: MainAxisAlignment.start,
          backgroundColor: selected ? theme.colorScheme.accent : null,
          leading: Icon(
            selected ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 14,
          ),
          onPressed: onPressed,
          child: Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    positive,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: positiveColor == null
                        ? null
                        : TextStyle(color: positiveColor),
                  ),
                ),
                Expanded(
                  child: Text(
                    negative,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: negativeColor == null
                        ? theme.textTheme.muted
                        : theme.textTheme.muted.copyWith(color: negativeColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
