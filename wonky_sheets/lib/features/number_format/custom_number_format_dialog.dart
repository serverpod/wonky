import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';
import 'mcp_dialog_state.dart';

/// Built-in examples of the custom number format dialog (04 §11.2).
const customNumberFormatExamples = [
  '#,##0.00',
  '#,##0',
  '0.00',
  '0%',
  '0.0%',
  '#,##0.00;(#,##0.00)',
  '#,##0;[Red]-#,##0',
  '0.00E+00',
  '# ?/?',
  '0.0,,"M"',
  '#,##0,"K"',
  '000-00-0000',
  '0 "items"',
  '[>1000]#,##0,"K";0',
  'yyyy-mm-dd',
  'dddd, mmmm d, yyyy',
  'h:mm AM/PM',
  '[h]:mm:ss',
  '@',
];

/// Custom number format (04 §11.2): pattern input (monospace) with the live
/// preview of the active cell's value and of sample values, parse errors
/// under the input, examples (built-ins and the spreadsheet's recent custom
/// formats) and a "Format codes" help section. Returns the pattern.
Future<String?> showCustomNumberFormatPatternDialog(
  BuildContext context, {
  required String initial,
  required String locale,
  required CellValue? activeValue,
  required List<String> recent,
}) => showShadDialog<String>(
  context: context,
  builder: (_) => CustomNumberFormatDialog(
    initial: initial,
    locale: locale,
    activeValue: activeValue,
    recent: recent,
  ),
);

class CustomNumberFormatDialog extends StatefulWidget {
  const CustomNumberFormatDialog({
    super.key,
    required this.initial,
    required this.locale,
    required this.activeValue,
    required this.recent,
  });

  final String initial;
  final String locale;
  final CellValue? activeValue;
  final List<String> recent;

  @override
  State<CustomNumberFormatDialog> createState() =>
      _CustomNumberFormatDialogState();
}

class _CustomNumberFormatDialogState
    extends McpDialogState<CustomNumberFormatDialog> {
  late final TextEditingController _pattern =
      TextEditingController(text: widget.initial)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initial.length,
        );
  bool _help = false;

  @override
  void dispose() {
    _pattern.dispose();
    super.dispose();
  }

  FormatParseError? get _error {
    final p = _pattern.text;
    if (p.trim().isEmpty) return null;
    return NumberFormatParser.validate(p);
  }

  bool get _valid => _pattern.text.trim().isNotEmpty && _error == null;

  void _apply() {
    if (_valid) close(_pattern.text);
  }

  void _load(String p) => setState(() {
    _pattern.text = p;
    _pattern.selection = TextSelection.collapsed(offset: p.length);
  });

  @override
  Map<String, Object?> describe() => {
    'title': 'Custom number format',
    'fields': [
      {
        'id': 'pattern',
        'label': 'Format pattern',
        'type': 'text',
        'value': _pattern.text,
        if (_error != null) 'error': _error!.message,
        'options': [...widget.recent, ...customNumberFormatExamples],
      },
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
      {'id': 'apply', 'label': 'Apply', 'enabled': _valid},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    if (id != 'pattern' || value is! String) return false;
    _load(value);
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        close();
        return true;
      case 'apply':
        if (!_valid) return false;
        _apply();
        return true;
    }
    return false;
  }

  String _fmt(CellValue v) => NumberFormatter.instance.formatText(
    v,
    _pattern.text.trim().isEmpty ? null : _pattern.text,
    locale: widget.locale,
  );

  Color? _color(CellValue v) {
    if (_pattern.text.trim().isEmpty) return null;
    final f = NumberFormatter.instance.format(
      v,
      _pattern.text,
      locale: widget.locale,
    );
    final c = f.colorArgb;
    return c == null ? null : Color(c);
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final err = _error;
    final active = widget.activeValue;
    final samples = <(String, CellValue)>[
      if (active != null && active is! EmptyValue) (l.numFmtActiveCell, active),
      (l.numFmtSamplePositive, const NumberValue(1234.56)),
      (l.numFmtSampleNegative, const NumberValue(-1234.56)),
      (l.numFmtSampleZero, const NumberValue(0)),
      (l.numFmtSampleText, const TextValue('Text')),
    ];
    const mono = TextStyle(fontFamily: 'GeistMono', package: 'shad');
    Widget example(String p) => ShadButton.ghost(
      key: ValueKey<String>('dialog.customNumberFormat.example.$p'),
      size: ShadButtonSize.sm,
      width: double.infinity,
      mainAxisAlignment: MainAxisAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onPressed: () => _load(p),
      child: Expanded(
        child: Row(
          children: [
            Expanded(
              child: Text(
                p,
                textAlign: TextAlign.start,
                style: mono.copyWith(fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                NumberFormatter.instance.formatText(
                  const NumberValue(1234.56),
                  p,
                  locale: widget.locale,
                ),
                style: theme.textTheme.muted.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => close(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.customNumberFormat'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.dialogCustomNumberFormatTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.customNumberFormat.cancel'),
            onPressed: () => close(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.customNumberFormat.apply'),
            enabled: _valid,
            onPressed: _apply,
            child: Text(l.dialogApply),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInput(
                  key: const ValueKey<String>(
                    'dialog.customNumberFormat.pattern',
                  ),
                  controller: _pattern,
                  autofocus: true,
                  style: mono,
                  placeholder: const Text('#,##0.00', style: mono),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _apply(),
                ),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l.numFmtParseError(err.position + 1, err.message),
                      key: const ValueKey<String>(
                        'dialog.customNumberFormat.error',
                      ),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(l.numFmtPreview, style: theme.textTheme.small),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      for (final (label, v) in samples)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: theme.textTheme.muted.copyWith(
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  err == null ? _fmt(v) : '—',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: err == null ? _color(v) : null,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.recent.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(l.numFmtRecent, style: theme.textTheme.small),
                  for (final p in widget.recent) example(p),
                ],
                const SizedBox(height: 12),
                Text(l.numFmtExamples, style: theme.textTheme.small),
                for (final p in customNumberFormatExamples) example(p),
                const SizedBox(height: 8),
                ShadButton.ghost(
                  key: const ValueKey<String>('dialog.customNumberFormat.help'),
                  size: ShadButtonSize.sm,
                  mainAxisAlignment: MainAxisAlignment.start,
                  leading: Icon(
                    _help ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 15,
                  ),
                  onPressed: () => setState(() => _help = !_help),
                  child: Text(l.numFmtCodesHelp),
                ),
                if (_help) _FormatCodesHelp(mono: mono),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatCodesHelp extends StatelessWidget {
  const _FormatCodesHelp({required this.mono});

  final TextStyle mono;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final rows = [
      ('0', l.numFmtCodeZero),
      ('#', l.numFmtCodeHash),
      ('?', l.numFmtCodeQuestion),
      ('.  ,', l.numFmtCodeSeparators),
      ('%', l.numFmtCodePercent),
      ('E+00', l.numFmtCodeExponent),
      ('"text"  \\c', l.numFmtCodeLiteral),
      ('@', l.numFmtCodeText),
      ('_c  *c', l.numFmtCodeSpacing),
      ('[Red]  [Color10]', l.numFmtCodeColor),
      ('[>1000]', l.numFmtCodeCondition),
      ('a;b;c;d', l.numFmtCodeSections),
      ('d m y h s', l.numFmtCodeDates),
      ('[h] [m] [s]', l.numFmtCodeElapsed),
      ('[\$€-407]', l.numFmtCodeCurrency),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (code, text) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(code, style: mono.copyWith(fontSize: 12)),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
