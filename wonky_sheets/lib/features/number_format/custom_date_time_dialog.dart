import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import 'date_time_pattern.dart';
import 'mcp_dialog_state.dart';

/// The sample shown for representations: 26 Sep 2008 15:59:07.123.
final double _sample = SerialCalendar.serialOfDateTime(
  2008,
  9,
  26,
  15,
  59,
  7.123,
);

/// Custom date and time (04 §11.3): presets plus a token builder whose chips
/// map 1:1 to pattern tokens (06 §5.6); free text between chips is literal.
/// Returns the pattern.
Future<String?> showCustomDateTimeDialog(
  BuildContext context, {
  required String initial,
  required String locale,
  required CellValue? activeValue,
}) => showShadDialog<String>(
  context: context,
  builder: (_) => CustomDateTimeDialog(
    initial: initial,
    locale: locale,
    activeValue: activeValue,
  ),
);

class CustomDateTimeDialog extends StatefulWidget {
  const CustomDateTimeDialog({
    super.key,
    required this.initial,
    required this.locale,
    required this.activeValue,
  });

  final String initial;
  final String locale;
  final CellValue? activeValue;

  @override
  State<CustomDateTimeDialog> createState() => _CustomDateTimeDialogState();
}

class _CustomDateTimeDialogState extends McpDialogState<CustomDateTimeDialog> {
  late List<DtPart> _parts = DateTimePatternCodec.parse(
    widget.initial.isEmpty ? dateTimePresets.first : widget.initial,
  );

  String get _pattern => DateTimePatternCodec.build(_parts);

  bool get _valid =>
      _parts.any((p) => !p.isLiteral) &&
      NumberFormatParser.validate(_pattern) == null;

  String _fmt(String pattern, [double? value]) =>
      NumberFormatter.instance.formatText(
        NumberValue(value ?? _sample),
        pattern,
        locale: widget.locale,
      );

  /// What a token renders like on the sample (minutes/seconds/AM-PM in
  /// context so `m` isn't read as a month).
  String _tokenSample(DtField f, String token) => switch (f) {
    DtField.minute => _fmt('h:$token').split(':').last,
    DtField.second => _fmt(token),
    DtField.millisecond => _fmt('ss$token').substring(2),
    DtField.ampm => _fmt('h $token').split(' ').last,
    _ => _fmt(token),
  };

  void _setPattern(String p) =>
      setState(() => _parts = DateTimePatternCodec.parse(p));

  void _apply() {
    if (_valid) close(_pattern);
  }

  @override
  Map<String, Object?> describe() => {
    'title': 'Custom date and time',
    'fields': [
      {
        'id': 'pattern',
        'label': 'Pattern',
        'type': 'text',
        'value': _pattern,
        'options': dateTimePresets,
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
    _setPattern(value);
    return true;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'cancel') {
      close();
      return true;
    }
    if (buttonId == 'apply' && _valid) {
      _apply();
      return true;
    }
    return false;
  }

  String _fieldLabel(SheetsLocalizations l, DtField f) => switch (f) {
    DtField.day => l.dtDay,
    DtField.weekday => l.dtWeekday,
    DtField.month => l.dtMonth,
    DtField.year => l.dtYear,
    DtField.hour => l.dtHour,
    DtField.minute => l.dtMinute,
    DtField.second => l.dtSecond,
    DtField.millisecond => l.dtMillisecond,
    DtField.ampm => l.dtAmPm,
    DtField.elapsedHours => l.dtElapsedHours,
    DtField.elapsedMinutes => l.dtElapsedMinutes,
    DtField.elapsedSeconds => l.dtElapsedSeconds,
  };

  void _replace(int i, DtPart p) => setState(() => _parts[i] = p);

  void _remove(int i) => setState(() {
    _parts.removeAt(i);
    // Merge neighbouring literals.
    if (i > 0 &&
        i < _parts.length &&
        _parts[i - 1].isLiteral &&
        _parts[i].isLiteral) {
      _parts[i - 1] = DtPart.literal(_parts[i - 1].text + _parts[i].text);
      _parts.removeAt(i);
    }
  });

  void _add(DtField? f) => setState(() {
    final needsSep = _parts.isNotEmpty && !_parts.last.isLiteral;
    if (f == null) {
      _parts.add(const DtPart.literal(' '));
      return;
    }
    if (needsSep && f != DtField.millisecond) {
      _parts.add(DtPart.literal(_defaultSeparator(_parts.last.field!, f)));
    }
    _parts.add(DtPart.token(f, f.tokens.first));
  });

  static String _defaultSeparator(DtField prev, DtField next) {
    const time = {
      DtField.hour,
      DtField.minute,
      DtField.second,
      DtField.elapsedHours,
      DtField.elapsedMinutes,
      DtField.elapsedSeconds,
    };
    if (time.contains(prev) && time.contains(next)) return ':';
    const date = {DtField.day, DtField.month, DtField.year};
    if (date.contains(prev) && date.contains(next)) return '/';
    return ' ';
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final active = widget.activeValue;
    final preview = active is NumberValue
        ? _fmt(_pattern, active.number)
        : _fmt(_pattern);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => close(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.customDateTime'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.dtDialogTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.customDateTime.cancel'),
            onPressed: () => close(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.customDateTime.apply'),
            enabled: _valid,
            onPressed: _apply,
            child: Text(l.dialogApply),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The builder.
                Container(
                  key: const ValueKey<String>('dialog.customDateTime.builder'),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (var i = 0; i < _parts.length; i++)
                        _parts[i].isLiteral
                            ? _LiteralChip(
                                key: ValueKey<String>('dt.literal.$i'),
                                text: _parts[i].text,
                                label: l.dtLiteral,
                                onChanged: (t) =>
                                    _replace(i, DtPart.literal(t)),
                              )
                            : WonkyDropdownMenu(
                                key: ValueKey<String>('dt.token.$i'),
                                entries: () => [
                                  WonkyMenuLabel(
                                    _fieldLabel(l, _parts[i].field!),
                                  ),
                                  for (final t in _parts[i].field!.tokens)
                                    WonkyMenuRadioItem(
                                      key: ValueKey<String>('dt.token.$i.$t'),
                                      label:
                                          '${_tokenSample(_parts[i].field!, t)}   ($t)',
                                      selected: _parts[i].text == t,
                                      onSelected: () => _replace(
                                        i,
                                        DtPart.token(_parts[i].field!, t),
                                      ),
                                    ),
                                  const WonkyMenuSeparator(),
                                  WonkyMenuItem(
                                    key: ValueKey<String>('dt.token.$i.remove'),
                                    label: l.dtRemove,
                                    icon: LucideIcons.x,
                                    onSelected: () => _remove(i),
                                  ),
                                ],
                                builder: (context, menu) => ShadButton.secondary(
                                  size: ShadButtonSize.sm,
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  onPressed: menu.toggle,
                                  trailing: const Icon(
                                    LucideIcons.chevronDown,
                                    size: 13,
                                  ),
                                  child: Text(
                                    '${_fieldLabel(l, _parts[i].field!)}: ${_tokenSample(_parts[i].field!, _parts[i].text)}',
                                  ),
                                ),
                              ),
                      WonkyDropdownMenu(
                        key: const ValueKey<String>('dt.add'),
                        entries: () => [
                          for (final f in DtField.values)
                            WonkyMenuItem(
                              key: ValueKey<String>('dt.add.${f.name}'),
                              label: _fieldLabel(l, f),
                              onSelected: () => _add(f),
                            ),
                          const WonkyMenuSeparator(),
                          WonkyMenuItem(
                            key: const ValueKey<String>('dt.add.text'),
                            label: l.dtLiteral,
                            onSelected: () => _add(null),
                          ),
                        ],
                        builder: (context, menu) => ShadIconButton.ghost(
                          width: 28,
                          height: 28,
                          iconSize: 15,
                          semanticLabel: l.dtAdd,
                          icon: const Icon(LucideIcons.plus),
                          onPressed: menu.toggle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(l.numFmtPreview, style: theme.textTheme.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preview,
                        key: const ValueKey<String>(
                          'dialog.customDateTime.preview',
                        ),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _pattern,
                    style: theme.textTheme.muted.copyWith(
                      fontFamily: 'GeistMono',
                      package: 'shad',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.dtPresets, style: theme.textTheme.small),
                const SizedBox(height: 4),
                for (final p in dateTimePresets)
                  ShadButton.ghost(
                    key: ValueKey<String>('dialog.customDateTime.preset.$p'),
                    size: ShadButtonSize.sm,
                    width: double.infinity,
                    mainAxisAlignment: MainAxisAlignment.start,
                    onPressed: () => _setPattern(p),
                    child: Expanded(
                      child: Text(
                        _fmt(p),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                      ),
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

/// An editable literal between tokens.
class _LiteralChip extends StatefulWidget {
  const _LiteralChip({
    super.key,
    required this.text,
    required this.label,
    required this.onChanged,
  });

  final String text;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  State<_LiteralChip> createState() => _LiteralChipState();
}

class _LiteralChipState extends State<_LiteralChip> {
  late final TextEditingController _c = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(_LiteralChip old) {
    super.didUpdateWidget(old);
    if (widget.text != _c.text) _c.text = widget.text;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = (_c.text.length * 8.0 + 22).clamp(30.0, 160.0);
    return Semantics(
      label: widget.label,
      textField: true,
      child: SizedBox(
        width: w,
        height: 28,
        child: ShadInput(
          controller: _c,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          onChanged: (t) {
            setState(() {});
            widget.onChanged(t);
          },
        ),
      ),
    );
  }
}
