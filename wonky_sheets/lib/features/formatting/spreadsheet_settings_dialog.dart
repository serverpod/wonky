import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/formula.dart'
    show FormulaLanguage, FormulaLocale;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../number_format/mcp_dialog_state.dart';

/// Spreadsheet locales offered by the settings dialog (id, English name).
const spreadsheetLocales = <(String, String)>[
  ('en_US', 'English (United States)'),
  ('en_GB', 'English (United Kingdom)'),
  ('en_AU', 'English (Australia)'),
  ('en_CA', 'English (Canada)'),
  ('en_IN', 'English (India)'),
  ('en_IE', 'English (Ireland)'),
  ('en_NZ', 'English (New Zealand)'),
  ('en_SG', 'English (Singapore)'),
  ('en_ZA', 'English (South Africa)'),
  ('de_DE', 'German (Germany)'),
  ('de_AT', 'German (Austria)'),
  ('de_CH', 'German (Switzerland)'),
  ('fr_FR', 'French (France)'),
  ('fr_BE', 'French (Belgium)'),
  ('fr_CA', 'French (Canada)'),
  ('fr_CH', 'French (Switzerland)'),
  ('es_ES', 'Spanish (Spain)'),
  ('es_MX', 'Spanish (Mexico)'),
  ('es_US', 'Spanish (United States)'),
  ('es_AR', 'Spanish (Argentina)'),
  ('es_CO', 'Spanish (Colombia)'),
  ('it_IT', 'Italian (Italy)'),
  ('it_CH', 'Italian (Switzerland)'),
  ('pt_BR', 'Portuguese (Brazil)'),
  ('pt_PT', 'Portuguese (Portugal)'),
  ('nl_NL', 'Dutch (Netherlands)'),
  ('nl_BE', 'Dutch (Belgium)'),
  ('sv_SE', 'Swedish (Sweden)'),
  ('nb_NO', 'Norwegian Bokmål (Norway)'),
  ('da_DK', 'Danish (Denmark)'),
  ('fi_FI', 'Finnish (Finland)'),
  ('is_IS', 'Icelandic (Iceland)'),
  ('pl_PL', 'Polish (Poland)'),
  ('cs_CZ', 'Czech (Czechia)'),
  ('sk_SK', 'Slovak (Slovakia)'),
  ('hu_HU', 'Hungarian (Hungary)'),
  ('ro_RO', 'Romanian (Romania)'),
  ('bg_BG', 'Bulgarian (Bulgaria)'),
  ('hr_HR', 'Croatian (Croatia)'),
  ('sl_SI', 'Slovenian (Slovenia)'),
  ('sr_RS', 'Serbian (Serbia)'),
  ('el_GR', 'Greek (Greece)'),
  ('tr_TR', 'Turkish (Türkiye)'),
  ('ru_RU', 'Russian (Russia)'),
  ('uk_UA', 'Ukrainian (Ukraine)'),
  ('lt_LT', 'Lithuanian (Lithuania)'),
  ('lv_LV', 'Latvian (Latvia)'),
  ('et_EE', 'Estonian (Estonia)'),
  ('ca_ES', 'Catalan (Spain)'),
  ('he_IL', 'Hebrew (Israel)'),
  ('ar_EG', 'Arabic (Egypt)'),
  ('fa_IR', 'Persian (Iran)'),
  ('hi_IN', 'Hindi (India)'),
  ('bn_IN', 'Bengali (India)'),
  ('ur_PK', 'Urdu (Pakistan)'),
  ('th_TH', 'Thai (Thailand)'),
  ('vi_VN', 'Vietnamese (Vietnam)'),
  ('id_ID', 'Indonesian (Indonesia)'),
  ('ms_MY', 'Malay (Malaysia)'),
  ('fil_PH', 'Filipino (Philippines)'),
  ('ja_JP', 'Japanese (Japan)'),
  ('ko_KR', 'Korean (South Korea)'),
  ('zh_CN', 'Chinese (China)'),
  ('zh_TW', 'Chinese (Taiwan)'),
  ('zh_HK', 'Chinese (Hong Kong)'),
  ('sw_KE', 'Swahili (Kenya)'),
  ('af_ZA', 'Afrikaans (South Africa)'),
];

/// IANA time zones with their current UTC offsets, sorted by offset.
List<(String, String)> timeZoneOptions() {
  if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
  final now = clock.now().toUtc();
  final out = <(String, int, String)>[];
  for (final e in tz.timeZoneDatabase.locations.entries) {
    final name = e.key;
    if (!name.contains('/') || name.startsWith('Etc/')) continue;
    final offset = e.value
        .timeZone(now.millisecondsSinceEpoch)
        .offset
        .inMilliseconds;
    out.add((name, offset, '${_gmt(offset)} $name'));
  }
  out.sort((a, b) {
    final c = a.$2.compareTo(b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [('UTC', '(GMT+00:00) UTC'), for (final x in out) (x.$1, x.$3)];
}

String _gmt(int offsetMs) {
  final m = offsetMs ~/ 60000;
  final sign = m < 0 ? '-' : '+';
  final a = m.abs();
  String two(int v) => v.toString().padLeft(2, '0');
  return '(GMT$sign${two(a ~/ 60)}:${two(a % 60)})';
}

/// The settings the dialog edits (04 §11.1).
class SpreadsheetSettings {
  const SpreadsheetSettings({
    required this.locale,
    required this.timeZone,
    required this.recalcMode,
    required this.iterativeCalc,
    required this.maxIterations,
    required this.convergenceThreshold,
    this.displayLanguage = '',
  });

  factory SpreadsheetSettings.of(SpreadsheetRecord r) => SpreadsheetSettings(
    locale: r.locale,
    timeZone: r.timeZone,
    recalcMode: r.recalcMode.name,
    iterativeCalc: r.iterativeCalc,
    maxIterations: r.maxIterations,
    convergenceThreshold: r.convergenceThreshold,
    displayLanguage: FormulaLanguage.forCode(r.displayLanguage)?.code ?? '',
  );

  final String locale;
  final String timeZone;
  final String recalcMode;
  final bool iterativeCalc;
  final int maxIterations;
  final double convergenceThreshold;

  /// Function names and booleans language (`''` = English, 04 §11.1, P2).
  final String displayLanguage;

  /// The `sheets.settings.update` arguments that differ from [old].
  Map<String, Object?> changesFrom(SpreadsheetSettings old) => {
    if (locale != old.locale) 'locale': locale,
    if (timeZone != old.timeZone) 'timeZone': timeZone,
    if (recalcMode != old.recalcMode) 'recalcMode': recalcMode,
    if (iterativeCalc != old.iterativeCalc) 'iterativeCalc': iterativeCalc,
    if (maxIterations != old.maxIterations) 'maxIterations': maxIterations,
    if (convergenceThreshold != old.convergenceThreshold)
      'convergenceThreshold': convergenceThreshold,
    if (displayLanguage != old.displayLanguage)
      'displayLanguage': displayLanguage,
  };
}

/// Spreadsheet settings (04 §11.1): *General* (locale with a live preview,
/// time zone) and *Calculation* (recalculation, iterative calculation).
/// Returns the changed settings.
Future<SpreadsheetSettings?> showSpreadsheetSettingsDialog(
  BuildContext context,
  SpreadsheetSettings current,
) => showShadDialog<SpreadsheetSettings>(
  context: context,
  builder: (_) => SpreadsheetSettingsDialog(initial: current),
);

class SpreadsheetSettingsDialog extends StatefulWidget {
  const SpreadsheetSettingsDialog({super.key, required this.initial});

  final SpreadsheetSettings initial;

  @override
  State<SpreadsheetSettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends McpDialogState<SpreadsheetSettingsDialog> {
  late String _locale = widget.initial.locale;
  late String _timeZone = widget.initial.timeZone;
  late String _language = widget.initial.displayLanguage;
  late String _recalc = widget.initial.recalcMode;
  late bool _iterative = widget.initial.iterativeCalc;
  late int _maxIterations = widget.initial.maxIterations;
  late final TextEditingController _threshold = TextEditingController(
    text: _num(widget.initial.convergenceThreshold),
  );
  String _tab = 'general';
  String _localeQuery = '';
  String _zoneQuery = '';
  late final List<(String, String)> _zones = timeZoneOptions();

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  double? get _thresholdValue {
    final v = double.tryParse(_threshold.text.trim().replaceAll(',', '.'));
    return v == null || v < 0 ? null : v;
  }

  bool get _valid => _thresholdValue != null;

  SpreadsheetSettings get _result => SpreadsheetSettings(
    locale: _locale,
    timeZone: _timeZone,
    recalcMode: _recalc,
    iterativeCalc: _iterative,
    maxIterations: _maxIterations,
    convergenceThreshold:
        _thresholdValue ?? widget.initial.convergenceThreshold,
    displayLanguage: _language,
  );

  void _save() {
    if (_valid) close(_result);
  }

  List<(String, String)> get _locales => [
    if (!spreadsheetLocales.any((x) => x.$1 == widget.initial.locale))
      (widget.initial.locale, widget.initial.locale),
    ...spreadsheetLocales,
  ];

  @override
  Map<String, Object?> describe() => {
    'title': 'Spreadsheet settings',
    'fields': [
      {
        'id': 'locale',
        'label': 'Locale',
        'type': 'select',
        'value': _locale,
        'options': [for (final x in _locales) x.$1],
      },
      {
        'id': 'timeZone',
        'label': 'Time zone',
        'type': 'select',
        'value': _timeZone,
      },
      {
        'id': 'displayLanguage',
        'label': 'Function language',
        'type': 'select',
        'value': _language,
        'options': ['', for (final x in FormulaLanguage.supported) x.code],
      },
      {
        'id': 'recalcMode',
        'label': 'Recalculation',
        'type': 'select',
        'value': _recalc,
        'options': [for (final m in RecalcMode.values) m.name],
      },
      {
        'id': 'iterativeCalc',
        'label': 'Iterative calculation',
        'type': 'checkbox',
        'value': _iterative,
      },
      {
        'id': 'maxIterations',
        'label': 'Max number of iterations',
        'type': 'number',
        'value': _maxIterations,
      },
      {
        'id': 'convergenceThreshold',
        'label': 'Threshold',
        'type': 'text',
        'value': _threshold.text,
      },
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
      {'id': 'save', 'label': 'Save settings', 'enabled': _valid},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'locale' when value is String:
        setState(() => _locale = value);
      case 'timeZone' when value is String:
        if (!_zones.any((z) => z.$1 == value)) return false;
        setState(() => _timeZone = value);
      case 'displayLanguage' when value is String:
        if (value.isNotEmpty && FormulaLanguage.forCode(value) == null) {
          return false;
        }
        setState(() => _language = value);
      case 'recalcMode' when value is String:
        if (!RecalcMode.values.any((m) => m.name == value)) return false;
        setState(() => _recalc = value);
      case 'iterativeCalc' when value is bool:
        setState(() => _iterative = value);
      case 'maxIterations':
        final n = value is num ? value.round() : int.tryParse('$value');
        if (n == null || n < 1 || n > 1000) return false;
        setState(() => _maxIterations = n);
      case 'convergenceThreshold':
        setState(() => _threshold.text = '$value');
      default:
        return false;
    }
    return true;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'cancel') {
      close();
      return true;
    }
    if (buttonId == 'save' && _valid) {
      _save();
      return true;
    }
    return false;
  }

  String _preview(String locale, [String language = '']) {
    final f = NumberFormatter.instance;
    String fmt(double v, String p) =>
        f.formatText(NumberValue(v), p, locale: locale);
    final date = SerialCalendar.serialOfDateTime(2008, 9, 26, 15, 59);
    final fl = FormulaLocale.forId(locale).withLanguage(language);
    final sep = fl.argSeparator;
    return [
      fmt(1234.56, '#,##0.00'),
      fmt(1234.56, NumberFormatPresets.currency),
      fmt(date, NumberFormatPresets.date),
      fmt(date, NumberFormatPresets.time),
      '=${fl.displayFunction('SUM')}(1$sep 2)',
    ].join(' · ');
  }

  String _recalcLabel(SheetsLocalizations l, String m) => switch (m) {
    'onChangeAndEveryMinute' => l.settingsRecalcMinute,
    'onChangeAndEveryHour' => l.settingsRecalcHour,
    _ => l.settingsRecalcOnChange,
  };

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(
      text,
      style: ShadTheme.of(
        context,
      ).textTheme.small.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _general(SheetsLocalizations l) {
    final theme = ShadTheme.of(context);
    final locales = _locales;
    final zones = _zones;
    String zoneLabel(String id) =>
        zones.where((z) => z.$1 == id).firstOrNull?.$2 ?? id;
    String localeLabel(String id) =>
        locales.where((x) => x.$1 == id).firstOrNull?.$2 ?? id;
    final lq = _localeQuery.toLowerCase();
    final zq = _zoneQuery.toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(l.settingsLocale),
        ShadSelect<String>.withSearch(
          key: const ValueKey<String>('dialog.settings.locale'),
          initialValue: _locale,
          minWidth: 300,
          maxHeight: 320,
          searchPlaceholder: Text(l.settingsSearch),
          onSearchChanged: (q) => setState(() => _localeQuery = q),
          options: [
            for (final (id, name) in locales)
              if (lq.isEmpty ||
                  name.toLowerCase().contains(lq) ||
                  id.toLowerCase().contains(lq))
                ShadOption(value: id, child: Text(name)),
          ],
          selectedOptionBuilder: (context, v) => Text(localeLabel(v)),
          onChanged: (v) {
            if (v != null) setState(() => _locale = v);
          },
        ),
        const SizedBox(height: 6),
        Text(
          _preview(_locale, _language),
          key: const ValueKey<String>('dialog.settings.preview'),
          style: theme.textTheme.muted.copyWith(fontSize: 12.5),
        ),
        if (_locale != widget.initial.locale)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.settingsLocaleNote,
              style: theme.textTheme.small.copyWith(fontSize: 12.5),
            ),
          ),
        _label(l.settingsTimeZone),
        ShadSelect<String>.withSearch(
          key: const ValueKey<String>('dialog.settings.timeZone'),
          initialValue: _timeZone,
          minWidth: 300,
          maxHeight: 320,
          searchPlaceholder: Text(l.settingsSearch),
          onSearchChanged: (q) => setState(() => _zoneQuery = q),
          options: [
            for (final (id, label) in zones)
              if (zq.isEmpty || label.toLowerCase().contains(zq))
                ShadOption(value: id, child: Text(label)),
          ],
          selectedOptionBuilder: (context, v) =>
              Text(zoneLabel(v), overflow: TextOverflow.ellipsis),
          onChanged: (v) {
            if (v != null) setState(() => _timeZone = v);
          },
        ),
        _label(l.settingsDisplayLanguage),
        ShadSelect<String>(
          key: const ValueKey<String>('dialog.settings.displayLanguage'),
          initialValue: _language,
          minWidth: 300,
          options: [
            ShadOption(
              value: '',
              child: Text(l.settingsDisplayLanguageEnglish),
            ),
            for (final x in FormulaLanguage.supported)
              ShadOption(value: x.code, child: Text(x.nativeName)),
          ],
          selectedOptionBuilder: (context, v) => Text(
            FormulaLanguage.forCode(v)?.nativeName ??
                l.settingsDisplayLanguageEnglish,
          ),
          onChanged: (v) {
            if (v != null) setState(() => _language = v);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l.settingsDisplayLanguageNote,
            style: theme.textTheme.muted.copyWith(fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _calculation(SheetsLocalizations l) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(l.settingsRecalc),
        ShadSelect<String>(
          key: const ValueKey<String>('dialog.settings.recalc'),
          initialValue: _recalc,
          options: [
            for (final m in RecalcMode.values)
              ShadOption(value: m.name, child: Text(_recalcLabel(l, m.name))),
          ],
          selectedOptionBuilder: (context, v) => Text(_recalcLabel(l, v)),
          onChanged: (v) {
            if (v != null) setState(() => _recalc = v);
          },
        ),
        const SizedBox(height: 14),
        ShadSwitch(
          key: const ValueKey<String>('dialog.settings.iterative'),
          value: _iterative,
          onChanged: (v) => setState(() => _iterative = v),
          label: Text(l.settingsIterative),
          sublabel: Text(l.settingsIterativeHint),
        ),
        _label(l.settingsMaxIterations),
        Align(
          alignment: Alignment.centerLeft,
          child: WonkyNumberStepper(
            key: const ValueKey<String>('dialog.settings.maxIterations'),
            value: _maxIterations,
            min: 1,
            max: 1000,
            enabled: _iterative,
            width: 140,
            semanticLabel: l.settingsMaxIterations,
            onChanged: (v) => setState(() => _maxIterations = v.round()),
          ),
        ),
        _label(l.settingsThreshold),
        SizedBox(
          width: 140,
          child: ShadInput(
            key: const ValueKey<String>('dialog.settings.threshold'),
            controller: _threshold,
            enabled: _iterative,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (!_valid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.settingsThresholdInvalid,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => close(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.settings'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.settingsDialogTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.settings.cancel'),
            onPressed: () => close(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.settings.save'),
            enabled: _valid,
            onPressed: _save,
            child: Text(l.settingsSave),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, minHeight: 300),
          child: ShadTabs<String>(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            tabs: [
              ShadTab(
                value: 'general',
                content: _general(l),
                child: Text(l.settingsGeneral),
              ),
              ShadTab(
                value: 'calculation',
                content: _calculation(l),
                child: Text(l.settingsCalculation),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
