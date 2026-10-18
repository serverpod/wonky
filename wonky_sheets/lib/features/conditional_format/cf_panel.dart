import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect, validateFormula;
import 'package:wonky_sheets_core/model.dart';

import '../../l10n/sheets_l10n.dart';
import '../common/range_input.dart';
import '../formatting/formatting_features.dart';
import '../formatting/formula_field.dart';
import '../formatting/panel_widgets.dart';
import '../formatting/sheets_colors.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'cf_controller.dart';
import 'cf_date_field.dart';
import 'cf_edit_state.dart';
import 'cf_paint.dart';
import 'cf_rule_text.dart';
import 'rule_preview_swatch.dart';

/// The *Conditional format rules* side panel (06 §15.9): the rule list of
/// the selection or sheet (reorder by drag or Alt+↑/↓, enable switch,
/// delete, hover highlights the ranges) and the rule editor (single color,
/// color scale, data bar, icon set) whose draft is previewed on the grid.
class CfPanel extends StatefulWidget {
  const CfPanel({super.key, required this.services, required this.editor});

  final ShellServices services;
  final SheetEditorController editor;

  @override
  State<CfPanel> createState() => _CfPanelState();
}

class _CfPanelState extends State<CfPanel> {
  CfEditState? _edit;
  List<GridRect>? _rects;
  bool _sheetScope = false;
  String? _lastSheet;

  /// Value fields the user changed since the editor opened: their errors
  /// show only after an interaction.
  final Set<String> _touched = {};

  SheetEditorController get ed => widget.editor;
  CfController get cf => FormattingFeatures.of(ed).cf;
  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    ed.addListener(_changed);
    cf.addListener(_changed);
    _lastSheet = ed.activeSheetId;
  }

  @override
  void didUpdateWidget(CfPanel old) {
    super.didUpdateWidget(old);
    if (old.editor != widget.editor) {
      old.editor.removeListener(_changed);
      FormattingFeatures.maybeOf(old.editor)?.cf.removeListener(_changed);
      ed.addListener(_changed);
      cf.addListener(_changed);
    }
  }

  @override
  void dispose() {
    ed.removeListener(_changed);
    final f = FormattingFeatures.maybeOf(ed);
    if (f != null) {
      f.cf.removeListener(_changed);
      f.cf.setDraft(null);
      f.cf.hoverRule(ed.activeSheetId, null);
    }
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (_lastSheet != ed.activeSheetId) {
      _lastSheet = ed.activeSheetId;
      // Rules belong to a sheet: an open editor is discarded on switch.
      if (_edit != null) _closeEditor();
    }
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // List actions.

  Future<bool> _run(String id, Map<String, Object?> args) async {
    final r = await s.invokeWithToasts(
      id,
      args: args,
      source: InvocationSource.ui,
      context: context,
    );
    return r.isOk;
  }

  String get _selectionText => ed.selection.resolved
      .toResolvedRanges()
      .map((r) => rangeToA1(ed.model, r, contextSheetId: ed.activeSheetId))
      .join(', ');

  void _addRule() {
    final st = CfEditState.newRule(_selectionText);
    _open(st);
  }

  void _editRule(CfRuleRecord rec) {
    final rects = cf.rectsOf(ed.activeSheetId, rec.id);
    final anchor = rects.isEmpty ? const GridRect(0, 0, 0, 0) : rects.first;
    final a1 = cfRuleToA1(
      rec.ruleJson,
      hooks: ed.hooks,
      sheetId: ed.activeSheetId,
      anchorRow: anchor.top,
      anchorCol: anchor.left,
      locale: ed.locale,
    );
    final st = CfEditState.fromRule(
      CfRule.parse(a1),
      rangeText: rectsToA1(rects),
      ruleId: rec.id,
      sortKey: rec.sortKey,
    );
    _open(st);
  }

  void _open(CfEditState st) {
    cf.hoverRule(ed.activeSheetId, null);
    setState(() {
      _edit = st;
      _touched.clear();
      _rects = _parseRects(st.rangeText);
    });
    _preview();
  }

  void _closeEditor() {
    cf.setDraft(null);
    setState(() {
      _edit = null;
      _rects = null;
    });
  }

  List<GridRect>? _parseRects(String text) {
    try {
      final list = parseRangeList(
        ed.model,
        text,
        contextSheetId: ed.activeSheetId,
      );
      if (list.isEmpty || list.any((r) => r.sheetId != ed.activeSheetId)) {
        return null;
      }
      final sheet = ed.activeSheet!;
      final grid = GridRect(
        0,
        0,
        sheet.rows.length - 1,
        sheet.columns.length - 1,
      );
      return [for (final r in list) r.rect.intersection(grid) ?? r.rect];
    } on InvalidRangeException {
      return null;
    }
  }

  /// Pushes the draft to the grid preview.
  void _preview() {
    final st = _edit;
    final rects = _rects;
    if (st == null || rects == null || rects.isEmpty) {
      cf.setDraft(null);
      return;
    }
    final anchor = rects.first;
    final String stored;
    try {
      stored = cfRuleToStored(
        st.toRule().toJson(),
        hooks: ed.hooks,
        sheetId: ed.activeSheetId,
        anchorRow: anchor.top,
        anchorCol: anchor.left,
        locale: ed.locale,
      );
    } catch (_) {
      cf.setDraft(null);
      return;
    }
    cf.setDraft(
      CfDraft(
        sheetId: ed.activeSheetId,
        ruleId: st.ruleId ?? '~draft',
        sortKey: st.sortKey ?? '\u{FFFF}',
        ranges: rects,
        rule: CfRule.parse(stored),
      ),
    );
  }

  void _update(void Function(CfEditState st) change) {
    final st = _edit;
    if (st == null) return;
    setState(() => change(st));
    _preview();
  }

  Future<void> _done() async {
    final st = _edit;
    if (st == null) return;
    final err = st.validate(
      rangesValid: _rects != null,
      locale: ed.locale,
      formulaLocale: ed.formulaLocale,
    );
    if (err != null) return;
    final rule = st.toRule().toJson();
    final ranges = [for (final r in _rects!) r.a1];
    final ok = st.ruleId == null
        ? await _run('sheets.cf.addRule', {'ranges': ranges, 'rule': rule})
        : await _run('sheets.cf.updateRule', {
            'ruleId': st.ruleId,
            'ranges': ranges,
            'rule': rule,
          });
    if (ok && mounted) _closeEditor();
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final st = _edit;
    return st == null ? _list(context) : _editor(context, st);
  }

  List<CfRuleRecord> _visibleRules() {
    final all = cf.rulesOf(ed.activeSheetId);
    if (_sheetScope) return all;
    final sel = ed.selection.resolved.ranges;
    return [
      for (final r in all)
        if (cf
            .rectsOf(ed.activeSheetId, r.id)
            .any((x) => sel.any((y) => y.rect.intersects(x))))
          r,
    ];
  }

  Widget _list(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final rules = _visibleRules();
    final all = cf.rulesOf(ed.activeSheetId);
    return FormatPanelFrame(
      key: const ValueKey<String>('cf.panel.list'),
      title: l.cfPanelTitle,
      children: [
        Row(
          children: [
            Text(l.cfShowRulesFor, style: theme.textTheme.muted),
            const SizedBox(width: 8),
            Expanded(
              child: PanelSelect<bool>(
                keyName: 'cf.scope',
                value: _sheetScope,
                options: {false: l.cfScopeSelection, true: l.cfScopeSheet},
                onChanged: (v) => setState(() => _sheetScope = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (rules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              all.isEmpty ? l.cfNoRules : l.cfNoRulesInSelection,
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
          )
        else
          _RuleList(
            rules: rules,
            all: all,
            editor: ed,
            cf: cf,
            onEdit: _editRule,
            onRun: _run,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.ghost(
            key: const ValueKey<String>('cf.add'),
            size: ShadButtonSize.sm,
            enabled: ed.canEdit && all.length < 500,
            leading: const Icon(LucideIcons.plus, size: 16),
            onPressed: _addRule,
            child: Text(l.cfAddRule),
          ),
        ),
        if (all.length >= 500)
          Text(l.cfLimitReached, style: theme.textTheme.muted),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Editor.

  String _errorText(SheetsLocalizations l, CfEditError e) => switch (e.kind) {
    CfEditErrorKind.range => l.rangeInputInvalid,
    CfEditErrorKind.emptyValue => l.cfErrorValue,
    CfEditErrorKind.formula => l.cfErrorFormula(e.message ?? ''),
    CfEditErrorKind.noFormat => l.cfErrorNoFormat,
  };

  Widget _editor(BuildContext context, CfEditState st) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final err = st.validate(
      rangesValid: _rects != null,
      locale: ed.locale,
      formulaLocale: ed.formulaLocale,
    );
    final kinds = {
      CfEditKind.single: l.cfTabSingle,
      CfEditKind.colorScale: l.cfTabColorScale,
      CfEditKind.dataBar: l.cfTabDataBar,
      CfEditKind.iconSet: l.cfTabIconSet,
    };
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _done,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _done,
      },
      child: FormatPanelFrame(
        key: const ValueKey<String>('cf.panel.editor'),
        title: st.ruleId == null ? l.cfAddRuleTitle : l.cfEditRuleTitle,
        onBack: _closeEditor,
        backLabel: la.actionCancel,
        footer: PanelDoneFooter(
          keyPrefix: 'cf.editor',
          cancelLabel: la.actionCancel,
          doneLabel: l.panelDone,
          onCancel: _closeEditor,
          onDone: err == null && ed.canEdit ? _done : null,
        ),
        children: [
          // One row of equal segments; labels scale down in narrow panels
          // instead of wrapping a lone segment onto a second line.
          Row(
            spacing: 4,
            children: [
              for (final e in kinds.entries)
                Expanded(
                  child: _Segment(
                    key: ValueKey<String>('cf.kind.${e.key.name}'),
                    label: e.value,
                    selected: st.kind == e.key,
                    onPressed: () => _update((x) => x.kind = e.key),
                  ),
                ),
            ],
          ),
          PanelSection(
            label: l.cfApplyToRange,
            child: RangeInput(
              keyName: 'cf.range',
              editor: ed,
              value: st.rangeText,
              onChanged: (t, ranges) {
                st.rangeText = t;
                _rects = ranges == null ? null : _parseRects(t);
                setState(() {});
                _preview();
              },
            ),
          ),
          ...switch (st.kind) {
            CfEditKind.single => _single(context, st),
            CfEditKind.colorScale => _colorScale(context, st),
            CfEditKind.dataBar => _dataBar(context, st),
            CfEditKind.iconSet => _iconSet(context, st),
          },
          // Single-color errors show under their field; the others once
          // the user changed a value.
          if (err != null &&
              err.kind != CfEditErrorKind.range &&
              st.kind != CfEditKind.single &&
              _touched.isNotEmpty)
            PanelError(
              _errorText(l, err),
              key: const ValueKey<String>('cf.editor.error'),
            ),
        ],
      ),
    );
  }

  Widget _valueInput(
    String keyName,
    String value,
    ValueChanged<String> onChanged, {
    String? placeholder,
    bool mono = false,
    bool enabled = true,
  }) => _TextField(
    key: ValueKey<String>(keyName),
    value: value,
    enabled: enabled,
    placeholder: placeholder,
    mono: mono,
    onChanged: (v) {
      _touched.add(keyName);
      onChanged(v);
    },
  );

  /// The error of value field [i] of a single-color rule, once touched.
  String? _valueError(SheetsLocalizations l, CfEditState st, int i) {
    if (!_touched.contains('cf.value.$i')) return null;
    final v = i < st.values.length ? st.values[i].trim() : '';
    if (v.isEmpty || v == '=') return l.cfErrorValue;
    return null;
  }

  /// The parse error of a `=formula` typed into value field [i].
  String? _fieldFormulaError(SheetsLocalizations l, String v, int i) {
    final t = v.trim();
    if (!t.startsWith('=') || t == '=') return null;
    try {
      final r = validateFormula(t, locale: ed.formulaLocale);
      return r.ok ? null : l.cfErrorFormula(r.error?.message ?? '');
    } catch (_) {
      return null;
    }
  }

  Widget _withError(Widget field, String? error, String keyName) =>
      error == null
      ? field
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            field,
            PanelError(error, key: ValueKey<String>('$keyName.error')),
          ],
        );

  List<Widget> _single(BuildContext context, CfEditState st) {
    final l = sheetsL10n(context);
    final theme = ed.model.theme;
    final options = <ConditionType, String>{};
    final groups = <ConditionType, String>{};
    for (final (g, types) in cfConditionGroups) {
      groups[types.first] = cfGroupLabel(l, g);
      for (final t in types) {
        options[t] = cfConditionLabel(l, t);
      }
    }
    final type = st.type;
    final valueFields = <Widget>[];
    if (type == ConditionType.customFormula) {
      valueFields.add(
        FormulaField(
          key: const ValueKey<String>('cf.formula'),
          keyName: 'cf.value.0',
          editor: ed,
          value: st.values.first,
          enabled: ed.canEdit,
          placeholder: '=\$B2>100',
          error: _valueError(l, st, 0),
          onChanged: (v) {
            _touched.add('cf.value.0');
            _update((x) => x.values[0] = v);
          },
        ),
      );
    } else if (type.family == ConditionFamily.date) {
      valueFields
        ..add(
          // Keyed by name: PanelSelect ignores null values, so "Exact
          // date" is the `exact` option.
          PanelSelect<String>(
            keyName: 'cf.date',
            value: st.relativeDate?.name ?? 'exact',
            options: {
              for (final d in RelativeDate.values)
                d.name: cfRelativeDateLabel(l, d),
              'exact': l.cfDateExact,
            },
            onChanged: (v) => _update(
              (x) => x.relativeDate = v == 'exact'
                  ? null
                  : RelativeDate.values.byName(v),
            ),
          ),
        )
        ..addAll([
          if (st.relativeDate == null) ...[
            const SizedBox(height: 6),
            _withError(
              CfDateField(
                key: const ValueKey<String>('cf.value.0'),
                value: st.values.first,
                placeholder: l.cfDatePlaceholder,
                pickLabel: l.cfPickDate,
                onChanged: (v) {
                  _touched.add('cf.value.0');
                  _update((x) => x.values[0] = v);
                },
              ),
              _valueError(l, st, 0),
              'cf.value.0',
            ),
          ],
        ]);
    } else {
      for (var i = 0; i < type.arity; i++) {
        if (i > 0) valueFields.add(const SizedBox(height: 6));
        valueFields.add(
          _withError(
            _valueInput(
              'cf.value.$i',
              st.values[i],
              (v) => _update((x) => x.values[i] = v),
              placeholder: l.cfValuePlaceholder,
            ),
            _valueError(l, st, i) ?? _fieldFormulaError(l, st.values[i], i),
            'cf.value.$i',
          ),
        );
      }
    }
    final f = st.format;
    final styleIds = {
      for (final p in CfPresets.formattingStyles) p.id: _styleLabel(l, p.id),
    };
    final currentStyle = CfPresets.formattingStyles
        .where((p) => _sameFormat(p.values, f))
        .map((p) => p.id)
        .firstOrNull;
    return [
      PanelSection(
        label: l.cfFormatCellsIf,
        child: PanelSelect<ConditionType>(
          keyName: 'cf.condition',
          value: type,
          options: options,
          groups: groups,
          onChanged: (t) => _update((x) {
            x.type = t;
            if (t == ConditionType.customFormula &&
                !x.values.first.startsWith('=')) {
              x.values[0] = '=';
            }
          }),
        ),
      ),
      if (valueFields.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: valueFields,
          ),
        ),
      PanelSection(
        label: l.cfFormattingStyle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RulePreviewSwatch(rule: st.toRule(), theme: theme),
                const SizedBox(width: 8),
                Expanded(
                  child: PanelSelect<String>(
                    keyName: 'cf.style',
                    value: currentStyle ?? 'custom',
                    options: {
                      if (currentStyle == null) 'custom': l.cfStyleCustom,
                      ...styleIds,
                    },
                    onChanged: (id) => _update((x) {
                      final p = CfPresets.formattingStyles
                          .where((p) => p.id == id)
                          .firstOrNull;
                      if (p != null) x.format = Map.of(p.values);
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (attr, icon, label) in [
                  (FormatAttr.bold, LucideIcons.bold, l.cfBold),
                  (FormatAttr.italic, LucideIcons.italic, l.cfItalic),
                  (FormatAttr.underline, LucideIcons.underline, l.cfUnderline),
                  (
                    FormatAttr.strikethrough,
                    LucideIcons.strikethrough,
                    l.cfStrikethrough,
                  ),
                ])
                  PanelIconToggle(
                    key: ValueKey<String>('cf.format.${attr.name}'),
                    icon: icon,
                    label: label,
                    value: f[attr] == true,
                    onChanged: (v) => _update((x) {
                      if (v) {
                        x.format[attr] = true;
                      } else {
                        x.format.remove(attr);
                      }
                    }),
                  ),
                SheetsColorButton(
                  key: const ValueKey<String>('cf.format.textColor'),
                  compact: true,
                  icon: LucideIcons.baseline,
                  label: l.cfTextColor,
                  resetLabel: l.colorAutomatic,
                  theme: theme,
                  value: f[FormatAttr.textColor] as String?,
                  onChanged: (c) => _update((x) {
                    if (c == null) {
                      x.format.remove(FormatAttr.textColor);
                    } else {
                      x.format[FormatAttr.textColor] = c;
                    }
                  }),
                ),
                SheetsColorButton(
                  key: const ValueKey<String>('cf.format.fillColor'),
                  compact: true,
                  icon: LucideIcons.paintBucket,
                  label: l.cfFillColor,
                  resetLabel: l.colorNone,
                  theme: theme,
                  value: f[FormatAttr.fillColor] as String?,
                  onChanged: (c) => _update((x) {
                    if (c == null) {
                      x.format.remove(FormatAttr.fillColor);
                    } else {
                      x.format[FormatAttr.fillColor] = c;
                    }
                  }),
                ),
              ],
            ),
            if (f.isEmpty)
              PanelError(
                l.cfErrorNoFormat,
                key: const ValueKey<String>('cf.format.error'),
              ),
          ],
        ),
      ),
      PanelSection(
        label: l.cfAdvanced,
        child: ShadCheckbox(
          key: const ValueKey<String>('cf.stopIfTrue'),
          value: st.stopIfTrue,
          onChanged: (v) => _update((x) => x.stopIfTrue = v),
          label: Text(l.cfStopIfTrue),
          sublabel: Text(l.cfStopIfTrueHint),
        ),
      ),
    ];
  }

  static bool _sameFormat(
    Map<FormatAttr, Object> a,
    Map<FormatAttr, Object> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  String _styleLabel(SheetsLocalizations l, String id) => switch (id) {
    'default' => l.cfStyleDefault,
    'greenFill' => l.cfStyleGreenFill,
    'yellowFill' => l.cfStyleYellowFill,
    'redFill' => l.cfStyleRedFill,
    'greenBold' => l.cfStyleGreenBold,
    'redBold' => l.cfStyleRedBold,
    'bold' => l.cfStyleBold,
    'italicGrey' => l.cfStyleItalicGrey,
    'strikeGrey' => l.cfStyleStrikeGrey,
    _ => id,
  };

  String _scaleLabel(SheetsLocalizations l, String id) => switch (id) {
    'whiteGreen' => l.cfScaleWhiteGreen,
    'greenWhite' => l.cfScaleGreenWhite,
    'whiteRed' => l.cfScaleWhiteRed,
    'redWhite' => l.cfScaleRedWhite,
    'redWhiteGreen' => l.cfScaleRedWhiteGreen,
    'greenWhiteRed' => l.cfScaleGreenWhiteRed,
    'redYellowGreen' => l.cfScaleRedYellowGreen,
    'greenYellowRed' => l.cfScaleGreenYellowRed,
    'whiteBlue' => l.cfScaleWhiteBlue,
    'blueWhite' => l.cfScaleBlueWhite,
    'yellowGreen' => l.cfScaleYellowGreen,
    _ => l.cfScaleAccent,
  };

  Widget _pointRow(
    BuildContext context,
    String keyName,
    String label,
    CfPointEdit p, {
    required List<CfValueKind?> kinds,
    required ValueChanged<CfPointEdit> onChanged,
    bool withColor = true,
  }) {
    final l = sheetsL10n(context);
    final k = p.kind;
    final needsValue =
        k != null && k != CfValueKind.min && k != CfValueKind.max;
    return PanelSection(
      label: label,
      top: 10,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: PanelSelect<CfValueKind?>(
              keyName: '$keyName.kind',
              value: k,
              options: {
                for (final x in kinds)
                  x: x == null ? l.cfKindNone : cfValueKindLabel(l, x),
              },
              onChanged: (v) => onChanged(p.copy()..kind = v),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: _valueInput(
              '$keyName.value',
              needsValue ? p.value : '',
              (v) => onChanged(p.copy()..value = v),
              enabled: needsValue,
              placeholder: needsValue ? l.cfValuePlaceholder : '',
            ),
          ),
          if (withColor) ...[
            const SizedBox(width: 4),
            SheetsColorButton(
              key: ValueKey<String>('$keyName.color'),
              compact: true,
              icon: LucideIcons.paintBucket,
              label: l.cfPointColor(label),
              enabled: k != null,
              theme: ed.model.theme,
              value: p.color,
              onChanged: (c) {
                if (c != null) onChanged(p.copy()..color = c);
              },
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _colorScale(BuildContext context, CfEditState st) {
    final l = sheetsL10n(context);
    final presets = CfPresets.colorScales(ed.model.theme);
    final rule = st.toRule();
    String? current;
    for (final p in presets) {
      if (p.rule.encode() == rule.encode()) current = p.id;
    }
    const valueKinds = [
      CfValueKind.number,
      CfValueKind.percent,
      CfValueKind.percentile,
      CfValueKind.formula,
    ];
    return [
      PanelSection(
        label: l.cfPreview,
        child: Row(
          children: [
            Expanded(
              child: RulePreviewSwatch(
                rule: rule,
                theme: ed.model.theme,
                width: double.infinity,
                height: 22,
              ),
            ),
          ],
        ),
      ),
      PanelSection(
        label: l.cfScalePreset,
        top: 10,
        child: PanelSelect<String>(
          keyName: 'cf.scale.preset',
          value: current ?? 'custom',
          options: {
            if (current == null) 'custom': l.cfStyleCustom,
            for (final p in presets) p.id: _scaleLabel(l, p.id),
          },
          optionBuilder: (context, id, label) {
            final p = presets.where((x) => x.id == id).firstOrNull;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p != null) ...[
                  RulePreviewSwatch(
                    rule: p.rule,
                    theme: ed.model.theme,
                    width: 28,
                    height: 14,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            );
          },
          onChanged: (id) {
            final p = presets.where((x) => x.id == id).firstOrNull;
            if (p != null) _update((x) => x.applyScale(p));
          },
        ),
      ),
      _pointRow(
        context,
        'cf.scale.min',
        l.cfMinpoint,
        st.points[0],
        kinds: const [CfValueKind.min, ...valueKinds],
        onChanged: (p) => _update((x) => x.points[0] = p),
      ),
      _pointRow(
        context,
        'cf.scale.mid',
        l.cfMidpoint,
        st.points[1],
        kinds: const [null, ...valueKinds],
        onChanged: (p) => _update((x) {
          if (x.points[1].kind == null && p.kind != null && p.value.isEmpty) {
            p.value = '50';
          }
          x.points[1] = p;
        }),
      ),
      _pointRow(
        context,
        'cf.scale.max',
        l.cfMaxpoint,
        st.points[2],
        kinds: const [CfValueKind.max, ...valueKinds],
        onChanged: (p) => _update((x) => x.points[2] = p),
      ),
    ];
  }

  List<Widget> _dataBar(BuildContext context, CfEditState st) {
    final l = sheetsL10n(context);
    final bar = st.bar;
    const valueKinds = [
      CfValueKind.number,
      CfValueKind.percent,
      CfValueKind.percentile,
      CfValueKind.formula,
    ];
    CfDataBarRule with_({
      String? color,
      String? negativeColor,
      bool? gradient,
      DataBarAxis? axis,
      DataBarDirection? direction,
      bool? showValue,
    }) => CfDataBarRule(
      color: color ?? bar.color,
      negativeColor: negativeColor ?? bar.negativeColor,
      gradient: gradient ?? bar.gradient,
      axis: axis ?? bar.axis,
      direction: direction ?? bar.direction,
      showValue: showValue ?? bar.showValue,
    );
    return [
      PanelSection(
        label: l.cfBarColors,
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.cfBarPositive),
            SheetsColorButton(
              key: const ValueKey<String>('cf.bar.color'),
              theme: ed.model.theme,
              label: l.cfBarPositive,
              value: bar.color,
              onChanged: (c) {
                if (c != null) _update((x) => x.bar = with_(color: c));
              },
            ),
            Text(l.cfBarNegative),
            SheetsColorButton(
              key: const ValueKey<String>('cf.bar.negativeColor'),
              theme: ed.model.theme,
              label: l.cfBarNegative,
              value: bar.negativeColor,
              onChanged: (c) {
                if (c != null) {
                  _update((x) => x.bar = with_(negativeColor: c));
                }
              },
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ShadCheckbox(
          key: const ValueKey<String>('cf.bar.gradient'),
          value: bar.gradient,
          onChanged: (v) => _update((x) => x.bar = with_(gradient: v)),
          label: Text(l.cfBarGradient),
        ),
      ),
      _pointRow(
        context,
        'cf.bar.min',
        l.cfMinpoint,
        st.barMin,
        withColor: false,
        kinds: const [CfValueKind.min, ...valueKinds],
        onChanged: (p) => _update((x) => x.barMin = p),
      ),
      _pointRow(
        context,
        'cf.bar.max',
        l.cfMaxpoint,
        st.barMax,
        withColor: false,
        kinds: const [CfValueKind.max, ...valueKinds],
        onChanged: (p) => _update((x) => x.barMax = p),
      ),
      PanelSection(
        label: l.cfBarAxis,
        top: 10,
        child: PanelSelect<DataBarAxis>(
          keyName: 'cf.bar.axis',
          value: bar.axis,
          options: {
            DataBarAxis.auto: l.cfAxisAuto,
            DataBarAxis.middle: l.cfAxisMiddle,
            DataBarAxis.none: l.cfAxisNone,
          },
          onChanged: (v) => _update((x) => x.bar = with_(axis: v)),
        ),
      ),
      PanelSection(
        label: l.cfBarDirection,
        top: 10,
        child: PanelSelect<DataBarDirection>(
          keyName: 'cf.bar.direction',
          value: bar.direction,
          options: {
            DataBarDirection.context: l.cfDirectionContext,
            DataBarDirection.ltr: l.cfDirectionLtr,
            DataBarDirection.rtl: l.cfDirectionRtl,
          },
          onChanged: (v) => _update((x) => x.bar = with_(direction: v)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ShadCheckbox(
          key: const ValueKey<String>('cf.bar.showValue'),
          value: bar.showValue,
          onChanged: (v) => _update((x) => x.bar = with_(showValue: v)),
          label: Text(l.cfShowValue),
        ),
      ),
    ];
  }

  List<Widget> _iconSet(BuildContext context, CfEditState st) {
    final l = sheetsL10n(context);
    final set = st.iconSet;
    final n = set.iconCount;
    int iconOf(int i) => st.iconReverse ? n - 1 - i : i;
    return [
      PanelSection(
        label: l.cfIconStyle,
        child: PanelSelect<IconSetKind>(
          keyName: 'cf.icons.set',
          value: set,
          options: {
            for (final k in IconSetKind.values) k: cfIconSetLabel(l, k),
          },
          optionBuilder: (context, k, label) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < k.iconCount; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: CfIconView(setId: k.id, index: i, size: 14),
                ),
              const SizedBox(width: 6),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
          onChanged: (k) => _update((x) => x.setIconSet(k)),
        ),
      ),
      for (var i = 0; i < n; i++)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              CfIconView(setId: set.id, index: iconOf(i), size: 18),
              const SizedBox(width: 8),
              if (i < n - 1) ...[
                SizedBox(
                  width: 58,
                  child: PanelSelect<bool>(
                    keyName: 'cf.icons.op.$i',
                    value: st.iconThresholds[i].inclusive,
                    options: const {true: '≥', false: '>'},
                    onChanged: (v) =>
                        _update((x) => x.iconThresholds[i].inclusive = v),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 5,
                  child: PanelSelect<CfValueKind>(
                    keyName: 'cf.icons.kind.$i',
                    value: st.iconThresholds[i].kind,
                    options: {
                      for (final k in const [
                        CfValueKind.number,
                        CfValueKind.percent,
                        CfValueKind.percentile,
                        CfValueKind.formula,
                      ])
                        k: cfValueKindLabel(l, k),
                    },
                    onChanged: (v) =>
                        _update((x) => x.iconThresholds[i].kind = v),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 4,
                  child: _valueInput(
                    'cf.icons.value.$i',
                    st.iconThresholds[i].value,
                    (v) => _update((x) => x.iconThresholds[i].value = v),
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    l.cfIconOtherwise,
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ShadCheckbox(
          key: const ValueKey<String>('cf.icons.reverse'),
          value: st.iconReverse,
          onChanged: (v) => _update((x) => x.iconReverse = v),
          label: Text(l.cfIconReverse),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: ShadCheckbox(
          key: const ValueKey<String>('cf.icons.showValue'),
          value: st.iconShowValue,
          onChanged: (v) => _update((x) => x.iconShowValue = v),
          label: Text(l.cfShowValue),
        ),
      ),
    ];
  }
}

/// A text input that keeps its own controller in sync with [value].
class _TextField extends StatefulWidget {
  const _TextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.mono = false,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final bool mono;
  final bool enabled;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(_TextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _c.text) _c.text = widget.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShadInput(
    controller: _c,
    enabled: widget.enabled,
    placeholder: widget.placeholder == null ? null : Text(widget.placeholder!),
    style: widget.mono
        ? const TextStyle(
            fontFamily: 'GeistMono',
            package: 'shad',
            fontSize: 13,
          )
        : null,
    onChanged: widget.onChanged,
  );
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Expanded(
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
    const padding = EdgeInsets.symmetric(horizontal: 6);
    return Semantics(
      selected: selected,
      child: selected
          ? ShadButton.secondary(
              size: ShadButtonSize.sm,
              width: double.infinity,
              padding: padding,
              onPressed: onPressed,
              child: child,
            )
          : ShadButton.ghost(
              size: ShadButtonSize.sm,
              width: double.infinity,
              padding: padding,
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}

/// The rule list with drag-and-drop and keyboard reordering.
class _RuleList extends StatelessWidget {
  const _RuleList({
    required this.rules,
    required this.all,
    required this.editor,
    required this.cf,
    required this.onEdit,
    required this.onRun,
  });

  final List<CfRuleRecord> rules;
  final List<CfRuleRecord> all;
  final SheetEditorController editor;
  final CfController cf;
  final ValueChanged<CfRuleRecord> onEdit;
  final Future<bool> Function(String id, Map<String, Object?> args) onRun;

  /// The rule that should follow [moved] when it lands at [index] of the
  /// displayed list (null = last).
  String? _beforeFor(CfRuleRecord moved, int index) {
    final list = [...rules]..remove(moved);
    final i = index.clamp(0, list.length);
    if (i < list.length) return list[i].id;
    if (list.isEmpty) return null;
    // After the last displayed rule: before its successor in the sheet.
    final prev = list.last;
    final at = all.indexWhere((r) => r.id == prev.id);
    for (var k = at + 1; k < all.length; k++) {
      if (all[k].id != moved.id) return all[k].id;
    }
    return null;
  }

  void _move(CfRuleRecord rule, int newIndex) {
    unawaited(
      onRun('sheets.cf.reorder', {
        'ruleId': rule.id,
        'beforeRuleId': ?_beforeFor(rule, newIndex),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rules.length,
      onReorderItem: (from, to) => _move(rules[from], to),
      itemBuilder: (context, i) {
        final rule = rules[i];
        return _RuleTile(
          key: ValueKey<String>('cf.rule.${rule.id}'),
          index: i,
          rule: rule,
          editor: editor,
          cf: cf,
          onEdit: () => onEdit(rule),
          onMove: (delta) {
            final to = i + delta;
            if (to < 0 || to >= rules.length) return;
            _move(rule, to);
          },
          onRun: onRun,
        );
      },
    );
  }
}

class _RuleTile extends StatefulWidget {
  const _RuleTile({
    super.key,
    required this.index,
    required this.rule,
    required this.editor,
    required this.cf,
    required this.onEdit,
    required this.onMove,
    required this.onRun,
  });

  final int index;
  final CfRuleRecord rule;
  final SheetEditorController editor;
  final CfController cf;
  final VoidCallback onEdit;
  final ValueChanged<int> onMove;
  final Future<bool> Function(String id, Map<String, Object?> args) onRun;

  @override
  State<_RuleTile> createState() => _RuleTileState();
}

class _RuleTileState extends State<_RuleTile> {
  bool _hover = false;
  bool _focused = false;

  void _setHover(bool v) {
    if (_hover == v) return;
    setState(() => _hover = v);
    widget.cf.hoverRule(
      widget.editor.activeSheetId,
      v || _focused ? widget.rule.id : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final ed = widget.editor;
    final rule = widget.rule;
    final rects = widget.cf.rectsOf(ed.activeSheetId, rule.id);
    final anchor = rects.isEmpty ? const GridRect(0, 0, 0, 0) : rects.first;
    final a1 = CfRule.parse(
      cfRuleToA1(
        rule.ruleJson,
        hooks: ed.hooks,
        sheetId: ed.activeSheetId,
        anchorRow: anchor.top,
        anchorCol: anchor.left,
        locale: ed.locale,
      ),
    );
    final summary = cfRuleSummary(l, a1);
    final active = _hover || _focused;
    return FocusableActionDetector(
      onShowHoverHighlight: _setHover,
      onShowFocusHighlight: (v) {
        setState(() => _focused = v);
        widget.cf.hoverRule(ed.activeSheetId, v || _hover ? rule.id : null);
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): _MoveIntent(
          1,
        ),
        SingleActivator(LogicalKeyboardKey.delete): _DeleteIntent(),
        SingleActivator(LogicalKeyboardKey.backspace): _DeleteIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onEdit();
            return null;
          },
        ),
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (i) {
            widget.onMove(i.delta);
            return null;
          },
        ),
        _DeleteIntent: CallbackAction<_DeleteIntent>(
          onInvoke: (_) {
            unawaited(
              widget.onRun('sheets.cf.deleteRule', {'ruleId': rule.id}),
            );
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        label: '$summary, ${rectsToA1(rects)}',
        hint: l.cfRuleHint,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onEdit,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.fromLTRB(2, 6, 4, 6),
            decoration: BoxDecoration(
              color: active ? theme.colorScheme.accent : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _focused
                    ? theme.colorScheme.ring
                    : theme.colorScheme.border,
              ),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        LucideIcons.gripVertical,
                        size: 16,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: rule.enabled ? 1 : 0.45,
                  child: RulePreviewSwatch(rule: a1, theme: ed.model.theme),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Opacity(
                    opacity: rule.enabled ? 1 : 0.55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.small,
                        ),
                        Text(
                          rectsToA1(rects),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                ShadTooltip(
                  builder: (_) =>
                      Text(rule.enabled ? l.cfDisableRule : l.cfEnableRule),
                  child: ShadSwitch(
                    key: ValueKey<String>('cf.rule.${rule.id}.enabled'),
                    value: rule.enabled,
                    enabled: ed.canEdit,
                    onChanged: (v) => unawaited(
                      widget.onRun('sheets.cf.setEnabled', {
                        'ruleId': rule.id,
                        'enabled': v,
                      }),
                    ),
                  ),
                ),
                ShadTooltip(
                  builder: (_) => Text(l.cfDeleteRule),
                  child: ShadIconButton.ghost(
                    key: ValueKey<String>('cf.rule.${rule.id}.delete'),
                    width: 28,
                    height: 28,
                    iconSize: 15,
                    enabled: ed.canEdit,
                    semanticLabel: l.cfDeleteRule,
                    icon: const Icon(LucideIcons.trash2),
                    onPressed: () => unawaited(
                      widget.onRun('sheets.cf.deleteRule', {'ruleId': rule.id}),
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

class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);
  final int delta;
}

class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

/// JSON of a rule for debugging/MCP descriptions.
String describeCfRule(CfRule rule) => jsonEncode(rule.toJson());
