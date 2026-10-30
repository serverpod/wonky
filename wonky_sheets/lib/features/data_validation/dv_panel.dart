import 'dart:async';
import 'dart:convert';

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../../theme/sheets_tokens.dart';
import '../common/range_input.dart';
import '../formatting/panel_widgets.dart';
import '../in_cell/in_cell_paint.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'dv_controller.dart';
import 'dv_draft.dart';
import 'dv_panel_state.dart';

/// The *Data validation rules* side panel (07 §6.3).
SidePanelSpec dvPanelSpec(
  BuildContext context,
  ShellServices services,
  SheetEditorController editor,
) => SidePanelSpec(
  id: dvPanelId,
  title: sheetsL10n(context).cmdDvOpenPanel,
  icon: LucideIcons.listChecks,
  builder: (context) => DvPanel(services: services, editor: editor),
);

/// Body of the data validation panel: the rules of the sheet, or the rule
/// editor of a draft.
class DvPanel extends StatelessWidget {
  const DvPanel({super.key, required this.services, required this.editor});

  final ShellServices services;
  final SheetEditorController editor;

  @override
  Widget build(BuildContext context) {
    final state = DvPanelState.of(editor);
    final dv = DataValidationController.of(editor);
    return ListenableBuilder(
      listenable: Listenable.merge([state, dv, editor]),
      builder: (context, _) {
        final draft = state.draft;
        if (draft == null) return _RuleList(editor: editor, dv: dv);
        return _RuleEditor(
          key: ValueKey<String>('dv.editor.${state.generation}'),
          editor: editor,
          state: state,
          draft: draft,
        );
      },
    );
  }
}

/// A short description of a rule's criteria ("Greater than 5").
String dvCriteriaSummary(
  SheetsLocalizations l,
  DvCriteria? criteria, {
  String Function(String stored)? formula,
}) {
  String v(ConditionValue x) => switch (x) {
    ConditionLiteral(:final text) => text,
    ConditionFormula(:final stored) => formula?.call(stored) ?? stored,
    ConditionRelativeDate(:final date) => switch (date) {
      RelativeDate.today => l.dvDateToday,
      RelativeDate.tomorrow => l.dvDateTomorrow,
      RelativeDate.yesterday => l.dvDateYesterday,
      RelativeDate.pastWeek => l.dvDatePastWeek,
      RelativeDate.pastMonth => l.dvDatePastMonth,
      RelativeDate.pastYear => l.dvDatePastYear,
    },
  };
  switch (criteria) {
    case null:
      return '';
    case DvListCriteria():
      return l.dvCritDropdown;
    case DvRangeCriteria():
      return l.dvCritDropdownRange;
    case DvCheckboxCriteria(:final checked, :final unchecked):
      return checked == null
          ? l.dvCritCheckbox
          : '${l.dvCritCheckbox} ($checked / ${unchecked ?? ''})';
    case DvConditionCriteria(:final condition):
      final kind = DvKind.ofCondition(condition.type);
      final label = kind?.label(l) ?? condition.type.id;
      final values = condition.values.map(v).where((s) => s.isNotEmpty);
      return values.isEmpty ? label : '$label ${values.join(' – ')}';
  }
}

class _RuleList extends StatelessWidget {
  const _RuleList({required this.editor, required this.dv});

  final SheetEditorController editor;
  final DataValidationController dv;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final sheet = editor.activeSheet;
    final rules = sheet == null
        ? const <DvRuleRecord>[]
        : (sheet.dvRules.values.toList()..sort((a, b) {
            final ra = sheet.ruleRects(RuleKind.dataValidation, a.id);
            final rb = sheet.ruleRects(RuleKind.dataValidation, b.id);
            if (ra.isEmpty || rb.isEmpty) return ra.length - rb.length;
            final c = ra.first.left.compareTo(rb.first.left);
            return c != 0 ? c : ra.first.top.compareTo(rb.first.top);
          }));
    final shadowed = sheet == null
        ? const <String>{}
        : DvRuleResolver.shadowedRuleIds(sheet);
    return FormatPanelFrame(
      title: l.cmdDvOpenPanel,
      children: [
        if (rules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  LucideIcons.listChecks,
                  size: 24,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(height: 8),
                Text(l.dvPanelEmpty, style: theme.textTheme.small),
                const SizedBox(height: 4),
                Text(
                  l.dvPanelEmptyHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.muted.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          )
        else
          for (final r in rules)
            _RuleRow(
              editor: editor,
              sheet: sheet!,
              record: r,
              shadowed: shadowed.contains(r.id),
            ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ShadButton.outline(
              key: const ValueKey<String>('dv.addRule'),
              size: ShadButtonSize.sm,
              enabled: editor.canEdit,
              leading: const Icon(LucideIcons.plus, size: 16),
              onPressed: () => DvPanelState.of(editor).startNew(),
              child: Flexible(
                child: Text(l.dvAddRule, overflow: TextOverflow.ellipsis),
              ),
            ),
            ShadButton.ghost(
              key: const ValueKey<String>('dv.clearSelection'),
              size: ShadButtonSize.sm,
              enabled: editor.canEdit && rules.isNotEmpty,
              onPressed: () =>
                  unawaited(editor.invokeCommand('sheets.dv.clearRange')),
              child: Flexible(
                child: Text(
                  l.dvRemoveAllInSelection,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RuleRow extends StatefulWidget {
  const _RuleRow({
    required this.editor,
    required this.sheet,
    required this.record,
    required this.shadowed,
  });

  final SheetEditorController editor;
  final SheetModel sheet;
  final DvRuleRecord record;
  final bool shadowed;

  @override
  State<_RuleRow> createState() => _RuleRowState();
}

/// A rule of the list: hovering or focusing it highlights its ranges on the
/// grid (07 §6.3); Enter edits it, Delete removes it.
class _RuleRowState extends State<_RuleRow> {
  bool _hover = false;
  bool _focused = false;

  DataValidationController get _dv =>
      DataValidationController.of(widget.editor);

  void _highlight({bool? hover, bool? focused}) {
    final h = hover ?? _hover;
    final f = focused ?? _focused;
    if (h == _hover && f == _focused) return;
    setState(() {
      _hover = h;
      _focused = f;
    });
    _dv.hoverRule(widget.sheet.id, h || f ? widget.record.id : null);
  }

  @override
  void dispose() {
    if (_hover || _focused) {
      final dv = _dv;
      final sid = widget.sheet.id;
      scheduleMicrotask(() => dv.hoverRule(sid, null));
    }
    super.dispose();
  }

  void _edit() {
    _dv.hoverRule(widget.sheet.id, null);
    DvPanelState.of(widget.editor).edit(widget.sheet.id, widget.record.id);
  }

  @override
  Widget build(BuildContext context) {
    final editor = widget.editor;
    final sheet = widget.sheet;
    final record = widget.record;
    final shadowed = widget.shadowed;
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final tokens = GridPaintTokens.ofContext(context);
    final rects = sheet.ruleRects(RuleKind.dataValidation, record.id);
    final where = rects.map((r) => r.a1).join(', ');
    final criteria = DvCriteria.tryParse(record.criteriaJson);
    final anchor = rects.isEmpty ? null : rects.first;
    final summary = dvCriteriaSummary(
      l,
      criteria,
      formula: anchor == null
          ? null
          : (stored) => editor.hooks.toA1(
              stored,
              sheetId: sheet.id,
              row: anchor.top,
              col: anchor.left,
              locale: editor.locale,
            ),
    );
    final options = criteria is DvListCriteria
        ? criteria.options
        : const <DvOption>[];
    final neutral = neutralChipColors(tokens);
    final canEdit = editor.canEdit;
    final active = _hover || _focused;
    return Semantics(
      button: canEdit,
      label: '$where, $summary',
      child: FocusableActionDetector(
        enabled: true,
        onShowHoverHighlight: (v) => _highlight(hover: v),
        onShowFocusHighlight: (v) => _highlight(focused: v),
        mouseCursor: canEdit
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.delete): _DeleteRuleIntent(),
          SingleActivator(LogicalKeyboardKey.backspace): _DeleteRuleIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (canEdit) _edit();
              return null;
            },
          ),
          _DeleteRuleIntent: CallbackAction<_DeleteRuleIntent>(
            onInvoke: (_) {
              if (canEdit) {
                unawaited(
                  editor.invokeCommand('sheets.dv.deleteRule', {
                    'ruleId': record.id,
                  }),
                );
              }
              return null;
            },
          ),
        },
        child: GestureDetector(
          key: ValueKey<String>('dv.rule.${record.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: canEdit ? _edit : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            decoration: BoxDecoration(
              color: active ? cs.accent : null,
              border: Border.all(color: _focused ? cs.ring : cs.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              where,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.small.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (shadowed) ...[
                            const SizedBox(width: 6),
                            ShadTooltip(
                              builder: (_) => Text(l.dvShadowed),
                              child: Icon(
                                LucideIcons.triangleAlert,
                                size: 14,
                                color: tokens.invalidTriangle,
                                semanticLabel: l.dvShadowed,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (options.isEmpty)
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        )
                      else
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final o in options.take(6))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: hexToColor(o.colors.bg) ?? neutral.bg,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  o.value,
                                  style: theme.textTheme.small.copyWith(
                                    fontSize: 11.5,
                                    color:
                                        hexToColor(o.colors.fg) ?? neutral.fg,
                                  ),
                                ),
                              ),
                            if (options.length > 6)
                              Text(
                                '+${options.length - 6}',
                                style: theme.textTheme.muted.copyWith(
                                  fontSize: 11.5,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (canEdit)
                  ShadTooltip(
                    builder: (_) => Text(l.dvRemoveRule),
                    child: ShadIconButton.ghost(
                      key: ValueKey<String>('dv.rule.remove.${record.id}'),
                      width: 28,
                      height: 28,
                      iconSize: 15,
                      semanticLabel: l.dvRemoveRule,
                      icon: const Icon(LucideIcons.trash2),
                      onPressed: () => unawaited(
                        editor.invokeCommand('sheets.dv.deleteRule', {
                          'ruleId': record.id,
                        }),
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

/// An option row of the dropdown editor with a stable key.
class _Option {
  _Option(this.id, DvOptionDraft d)
    : text = TextEditingController(text: d.value),
      colors = d.colors;

  final int id;
  final TextEditingController text;
  DvChipColors colors;
  final FocusNode focus = FocusNode();

  void dispose() {
    text.dispose();
    focus.dispose();
  }
}

class _RuleEditor extends StatefulWidget {
  const _RuleEditor({
    super.key,
    required this.editor,
    required this.state,
    required this.draft,
  });

  final SheetEditorController editor;
  final DvPanelState state;
  final DvDraft draft;

  @override
  State<_RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<_RuleEditor> {
  late DvDraft d = widget.draft;
  late final List<_Option> _options;
  late final TextEditingController _v1 = TextEditingController(
    text: d.values[0],
  );
  late final TextEditingController _v2 = TextEditingController(
    text: d.values[1],
  );
  late final TextEditingController _checked = TextEditingController(
    text: d.checked,
  );
  late final TextEditingController _unchecked = TextEditingController(
    text: d.unchecked,
  );
  late final TextEditingController _help = TextEditingController(
    text: d.helpText,
  );
  var _nextId = 0;
  List<ResolvedRange>? _ranges;
  List<ResolvedRange>? _source;
  bool _advanced = false;
  String? _error;

  SheetEditorController get ed => widget.editor;

  @override
  void initState() {
    super.initState();
    _options = [for (final o in d.options) _Option(_nextId++, o)];
    _ranges = _parse(d.rangesText);
    _source = _parse(d.sourceRange);
    _advanced = d.strict || d.helpEnabled || d.style != DvDisplayStyle.chip;
    if (widget.state.focusFirstItem && _options.isNotEmpty) {
      widget.state.focusFirstItem = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _options.first.focus.requestFocus();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preview();
    });
  }

  DvDraftPreview? _shown;

  /// Pushes the draft to the grid preview (07 §6.3): chips, checkboxes and
  /// invalid markers follow it until *Done* or *Cancel*.
  void _preview() {
    if (!mounted) return;
    final dv = DataValidationController.of(ed);
    final next = _previewOf(_current);
    _shown = next;
    dv.setDraft(next);
  }

  DvDraftPreview? _previewOf(DvDraft draft) {
    final ranges = _ranges;
    if (ranges == null || ranges.isEmpty) return null;
    final sid = ranges.first.sheetId;
    if (ranges.any((r) => r.sheetId != sid)) return null;
    final sheet = ed.model.sheet(sid);
    if (sheet == null) return null;
    if (draft.criteriaError(sheetsL10n(context)) != null) return null;
    if (draft.kind == DvKind.dropdownRange && _source == null) return null;
    final grid = sheet.gridRect;
    final rects = [
      for (final r in ranges)
        grid == null ? r.rect : (r.rect.intersection(grid) ?? r.rect),
    ];
    try {
      GridRange? source;
      final src = _source;
      if (draft.kind == DvKind.dropdownRange && src != null) {
        final x = src.first;
        source = ed.model
            .sheet(x.sheetId)!
            .gridRange(
              x.rect,
              wholeRows: x.wholeRows,
              wholeColumns: x.wholeColumns,
            );
      }
      final anchor = rects.first;
      final criteria = draft.criteriaJson(
        codec: EditorDvCodec(ed),
        anchor: GridRect(anchor.top, anchor.left, anchor.top, anchor.left),
        source: source,
      );
      return DvDraftPreview(
        record: DvRuleRecord(
          id: '~dv.draft',
          sheetId: sid,
          rangesJson: jsonEncode([
            for (final r in rects) sheet.gridRange(r).toJson(),
          ]),
          criteriaJson: jsonEncode(criteria),
          strict: draft.strict,
          showDropdown: draft.style != DvDisplayStyle.plainText,
          displayStyle: draft.style.name,
          helpText: draft.helpEnabled ? draft.helpText.trim() : null,
        ),
        rects: rects,
        replacesRuleId: draft.ruleId,
      );
    } catch (_) {
      return null;
    }
  }

  /// The draft changed: keep the panel state and the preview in sync.
  void _changed() {
    widget.state.draft = _current;
    _preview();
  }

  List<ResolvedRange>? _parse(String text) {
    if (text.trim().isEmpty) return null;
    try {
      final list = parseRangeList(
        ed.model,
        text,
        contextSheetId: ed.activeSheetId,
      );
      return list.isEmpty ? null : list;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    // End the preview (after this frame: the next editor may already show
    // its own draft).
    final shown = _shown;
    final dv = DataValidationController.of(ed);
    scheduleMicrotask(() {
      if (identical(dv.draft, shown)) dv.setDraft(null);
    });
    for (final o in _options) {
      o.dispose();
    }
    _v1.dispose();
    _v2.dispose();
    _checked.dispose();
    _unchecked.dispose();
    _help.dispose();
    super.dispose();
  }

  DvDraft get _current => d.copyWith(
    options: [
      for (final o in _options) DvOptionDraft(o.text.text, colors: o.colors),
    ],
    values: [_v1.text, _v2.text],
    checked: _checked.text,
    unchecked: _unchecked.text,
    helpText: _help.text,
  );

  void _set(DvDraft next) {
    setState(() {
      d = next;
      _error = null;
    });
    _changed();
  }

  void _addOption() {
    setState(() {
      final o = _Option(
        _nextId++,
        DvOptionDraft('', colors: DvChipPalette.at(_options.length)),
      );
      _options.add(o);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) o.focus.requestFocus();
      });
    });
  }

  void _removeOption(_Option o) {
    setState(() {
      _options.remove(o);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => o.dispose());
    _changed();
  }

  void _moveOption(_Option o, int delta) {
    final i = _options.indexOf(o);
    _reorder(i, i + delta);
  }

  /// Moves the item at [from] to [to] (drag or Alt+↑/↓).
  void _reorder(int from, int to) {
    if (from < 0 || from >= _options.length) return;
    if (to < 0 || to >= _options.length || to == from) return;
    setState(() {
      final o = _options.removeAt(from);
      _options.insert(to, o);
    });
    _changed();
  }

  Future<void> _done() async {
    final l = sheetsL10n(context);
    final draft = _current;
    final ranges = _ranges;
    if (ranges == null || ranges.isEmpty) {
      setState(() => _error = l.dvErrorRange);
      return;
    }
    final err = draft.criteriaError(l);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (draft.kind == DvKind.dropdownRange && _source == null) {
      setState(() => _error = l.dvErrorRange);
      return;
    }
    final first = ranges.first;
    final sheet = ed.model.sheet(first.sheetId)!;
    final grid = sheet.gridRect;
    final anchor = grid == null
        ? first.rect
        : (first.rect.intersection(grid) ?? first.rect);
    GridRange? source;
    final src = _source;
    if (draft.kind == DvKind.dropdownRange && src != null) {
      final s = src.first;
      source = ed.model
          .sheet(s.sheetId)!
          .gridRange(
            s.rect,
            wholeRows: s.wholeRows,
            wholeColumns: s.wholeColumns,
          );
    }
    final criteria = draft.criteriaJson(
      codec: EditorDvCodec(ed),
      anchor: GridRect(anchor.top, anchor.left, anchor.top, anchor.left),
      source: source,
    );
    final ok = await ed.invokeCommand('sheets.dv.saveRule', {
      if (draft.ruleId != null) 'ruleId': draft.ruleId,
      'ranges': [draft.rangesText],
      'criteria': criteria,
      'strict': draft.strict,
      'displayStyle': draft.style.name,
      'helpText': draft.helpEnabled ? draft.helpText.trim() : '',
    });
    if (ok && mounted) widget.state.close();
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return FormatPanelFrame(
      title: d.isNew ? l.dvAddRule : l.cmdDvOpenPanel,
      onBack: widget.state.close,
      backLabel: la.actionBack,
      footer: PanelDoneFooter(
        keyPrefix: 'dv',
        cancelLabel: la.actionCancel,
        doneLabel: la.actionDone,
        onCancel: widget.state.close,
        onDone: ed.canEdit ? () => unawaited(_done()) : null,
        leading: d.isNew
            ? null
            : ShadButton.ghost(
                key: const ValueKey<String>('dv.removeRule'),
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.trash2, size: 15),
                onPressed: () => unawaited(
                  ed.invokeCommand('sheets.dv.deleteRule', {
                    'ruleId': d.ruleId,
                  }),
                ),
                child: Text(l.dvRemoveRule, overflow: TextOverflow.ellipsis),
              ),
      ),
      children: [
        PanelSection(
          top: 4,
          label: l.dvApplyToRange,
          child: RangeInput(
            keyName: 'dv.ranges',
            editor: ed,
            value: d.rangesText,
            onChanged: (text, ranges) {
              _ranges = ranges;
              _set(d.copyWith(rangesText: text));
            },
          ),
        ),
        PanelSection(
          label: l.dvCriteria,
          child: PanelSelect<DvKind>(
            keyName: 'dv.criteria',
            value: d.kind,
            options: {for (final k in DvKind.values) k: k.label(l)},
            groups: {
              DvKind.textContains: l.dvGroupText,
              DvKind.dateIsValid: l.dvGroupDate,
              DvKind.numberGreater: l.dvGroupNumber,
              DvKind.checkbox: l.dvGroupOther,
            },
            onChanged: (k) => _set(d.copyWith(kind: k)),
          ),
        ),
        const SizedBox(height: 8),
        ..._criteriaEditor(context),
        if (_error != null) PanelError(_error!),
        const SizedBox(height: 12),
        GestureDetector(
          key: const ValueKey<String>('dv.advanced'),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _advanced = !_advanced),
          child: Semantics(
            button: true,
            expanded: _advanced,
            child: Row(
              children: [
                Icon(
                  _advanced
                      ? LucideIcons.chevronDown
                      : LucideIcons.chevronRight,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  l.dvAdvanced,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_advanced) ..._advancedOptions(context),
      ],
    );
  }

  List<Widget> _criteriaEditor(BuildContext context) {
    final l = sheetsL10n(context);
    switch (d.kind) {
      case DvKind.dropdown:
        return [
          ReorderableList(
            key: const ValueKey<String>('dv.options'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _options.length,
            onReorderItem: _reorder,
            proxyDecorator: (child, index, animation) =>
                _dragProxy(context, child),
            itemBuilder: (context, i) => _optionRow(context, _options[i]),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ShadButton.ghost(
              key: const ValueKey<String>('dv.addItem'),
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.plus, size: 15),
              onPressed: _addOption,
              child: Text(l.dvAddItem),
            ),
          ),
        ];
      case DvKind.dropdownRange:
        return [
          RangeInput(
            keyName: 'dv.source',
            editor: ed,
            value: d.sourceRange,
            multiple: false,
            placeholder: l.dvSourceRange,
            onChanged: (text, ranges) {
              _source = ranges;
              _set(d.copyWith(sourceRange: text));
            },
          ),
        ];
      case DvKind.checkbox:
        return [
          ShadCheckbox(
            key: const ValueKey<String>('dv.customValues'),
            value: d.customCheckbox,
            onChanged: (v) => _set(d.copyWith(customCheckbox: v)),
            label: Text(l.dvUseCustomValues),
          ),
          if (d.customCheckbox) ...[
            const SizedBox(height: 8),
            _labeled(context, l.dvChecked, _checked, 'dv.checked'),
            const SizedBox(height: 6),
            _labeled(context, l.dvUnchecked, _unchecked, 'dv.unchecked'),
          ],
        ];
      default:
        final n = d.kind.arity;
        if (n == 0) return const [];
        final relative = d.kind.isDate && n == 1;
        return [
          if (relative) ...[
            PanelSelect<DvDateChoice>(
              keyName: 'dv.dateChoice',
              value: d.dateChoice,
              options: {for (final c in DvDateChoice.values) c: c.label(l)},
              onChanged: (c) => _set(d.copyWith(dateChoice: c)),
            ),
            const SizedBox(height: 6),
          ],
          if (!relative || d.dateChoice == DvDateChoice.exact)
            _valueInput(
              context,
              _v1,
              'dv.value1',
              n == 2 ? l.dvValueMin : l.dvValueFormula,
            ),
          if (n == 2) ...[
            const SizedBox(height: 6),
            _valueInput(context, _v2, 'dv.value2', l.dvValueMax),
          ],
        ];
    }
  }

  Widget _valueInput(
    BuildContext context,
    TextEditingController c,
    String key,
    String placeholder,
  ) => ShadInput(
    key: ValueKey<String>(key),
    controller: c,
    placeholder: Text(d.kind == DvKind.customFormula ? '=B2>A2' : placeholder),
    style: d.kind == DvKind.customFormula
        ? const TextStyle(fontFamily: WonkyFonts.geistMono, fontSize: 13)
        : null,
    onChanged: (_) {
      _changed();
      if (_error != null) setState(() => _error = null);
    },
  );

  Widget _labeled(
    BuildContext context,
    String label,
    TextEditingController c,
    String key,
  ) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        SizedBox(width: 84, child: Text(label, style: theme.textTheme.small)),
        Expanded(
          child: ShadInput(
            key: ValueKey<String>(key),
            controller: c,
            onChanged: (_) => _changed(),
          ),
        ),
      ],
    );
  }

  /// The lifted item while it is dragged.
  Widget _dragProxy(BuildContext context, Widget child) {
    final cs = ShadTheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// One dropdown item: drag handle (or Alt+↑/↓ in the field), chip
  /// color, value, remove.
  Widget _optionRow(BuildContext context, _Option o) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final index = _options.indexOf(o);
    final label = o.text.text.isEmpty
        ? l.dvItemPlaceholder(index + 1)
        : o.text.text;
    final last = _options.length - 1;
    return Padding(
      key: ValueKey<String>('dv.option.row.${o.id}'),
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        customSemanticsActions: {
          if (index > 0)
            CustomSemanticsAction(label: l.dvItemMoveUp): () =>
                _moveOption(o, -1),
          if (index < last)
            CustomSemanticsAction(label: l.dvItemMoveDown): () =>
                _moveOption(o, 1),
        },
        child: Row(
          children: [
            ReorderableDragStartListener(
              key: ValueKey<String>('dv.option.$index.drag'),
              index: index,
              enabled: _options.length > 1,
              child: MouseRegion(
                cursor: _options.length > 1
                    ? SystemMouseCursors.grab
                    : SystemMouseCursors.basic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  child: Icon(
                    LucideIcons.gripVertical,
                    size: 16,
                    color: theme.colorScheme.mutedForeground,
                    semanticLabel: l.dvItemDragHint,
                  ),
                ),
              ),
            ),
            _ChipColorButton(
              keyName: 'dv.option.$index.color',
              colors: o.colors,
              label: l.dvItemColor(label),
              onChanged: (c) {
                setState(() => o.colors = c);
                _changed();
              },
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
                      _MoveItemIntent(-1),
                  SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
                      _MoveItemIntent(1),
                },
                child: Actions(
                  actions: {
                    _MoveItemIntent: CallbackAction<_MoveItemIntent>(
                      onInvoke: (i) {
                        _moveOption(o, i.delta);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) o.focus.requestFocus();
                        });
                        return null;
                      },
                    ),
                  },
                  child: ShadInput(
                    key: ValueKey<String>('dv.option.$index'),
                    controller: o.text,
                    focusNode: o.focus,
                    placeholder: Text(l.dvItemPlaceholder(index + 1)),
                    onChanged: (_) => _changed(),
                    onSubmitted: (_) {
                      if (index == _options.length - 1) _addOption();
                    },
                  ),
                ),
              ),
            ),
            _SmallIcon(
              keyName: 'dv.option.$index.remove',
              icon: LucideIcons.x,
              label: l.dvItemRemove(label),
              onPressed: _options.length > 1 ? () => _removeOption(o) : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _advancedOptions(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    return [
      PanelSection(
        label: l.dvIfInvalid,
        child: ShadRadioGroup<bool>(
          key: ValueKey<String>('dv.strict.${d.strict}'),
          initialValue: d.strict,
          onChanged: (v) => _set(d.copyWith(strict: v ?? false)),
          items: [
            ShadRadio(
              key: const ValueKey<String>('dv.strict.warn'),
              value: false,
              label: Text(l.dvShowWarning),
            ),
            ShadRadio(
              key: const ValueKey<String>('dv.strict.reject'),
              value: true,
              label: Text(l.dvRejectInput),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ShadCheckbox(
        key: const ValueKey<String>('dv.helpEnabled'),
        value: d.helpEnabled,
        onChanged: (v) => _set(d.copyWith(helpEnabled: v)),
        label: Text(l.dvShowHelpText),
      ),
      if (d.helpEnabled) ...[
        const SizedBox(height: 6),
        ShadTextarea(
          key: const ValueKey<String>('dv.helpText'),
          controller: _help,
          placeholder: Text(l.dvHelpTextPlaceholder),
          minHeight: 60,
          onChanged: (_) => _changed(),
        ),
      ],
      if (d.kind.isDropdown) ...[
        PanelSection(
          label: l.dvDisplayStyle,
          child: ShadRadioGroup<DvDisplayStyle>(
            key: ValueKey<String>('dv.style.${d.style.name}'),
            initialValue: d.style,
            onChanged: (v) => _set(d.copyWith(style: v ?? DvDisplayStyle.chip)),
            items: [
              for (final (s, label) in [
                (DvDisplayStyle.chip, l.dvStyleChip),
                (DvDisplayStyle.arrow, l.dvStyleArrow),
                (DvDisplayStyle.plainText, l.dvStylePlain),
              ])
                ShadRadio(
                  key: ValueKey<String>('dv.style.option.${s.name}'),
                  value: s,
                  label: Text(label),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ShadCheckbox(
          key: const ValueKey<String>('dv.allowMultiple'),
          value: d.allowMultiple,
          onChanged: (v) => _set(d.copyWith(allowMultiple: v)),
          label: Text(l.dvAllowMultiple, style: theme.textTheme.small),
        ),
      ],
    ];
  }
}

class _DeleteRuleIntent extends Intent {
  const _DeleteRuleIntent();
}

class _MoveItemIntent extends Intent {
  const _MoveItemIntent(this.delta);
  final int delta;
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ShadTooltip(
    builder: (_) => Text(label),
    child: ShadIconButton.ghost(
      key: ValueKey<String>(keyName),
      width: 26,
      height: 26,
      iconSize: 14,
      semanticLabel: label,
      icon: Icon(icon),
      onPressed: onPressed,
    ),
  );
}

/// A swatch button opening a `WonkyColorPicker` for the chip background
/// (07 §6.3): *No color*, the full palette, the 10 chip pairs as the
/// "Chip colors" row and custom colors. A pair keeps its text color; any
/// other background gets a readable text color of the same hue
/// ([chipTextColorFor]).
class _ChipColorButton extends StatefulWidget {
  const _ChipColorButton({
    required this.keyName,
    required this.colors,
    required this.label,
    required this.onChanged,
  });

  final String keyName;
  final DvChipColors colors;
  final String label;
  final ValueChanged<DvChipColors> onChanged;

  @override
  State<_ChipColorButton> createState() => _ChipColorButtonState();
}

class _ChipColorButtonState extends State<_ChipColorButton> {
  final _popover = ShadPopoverController();

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  Widget _swatch(BuildContext context, DvChipColors c, {double size = 18}) {
    final tokens = GridPaintTokens.ofContext(context);
    final neutral = neutralChipColors(tokens);
    final cs = ShadTheme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hexToColor(c.bg) ?? neutral.bg,
        shape: BoxShape.circle,
        border: Border.all(color: cs.border),
      ),
      child: c.isEmpty
          ? Icon(LucideIcons.ban, size: size * 0.6, color: cs.mutedForeground)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final ui = WonkyUiLocalizations.of(context);
    final names = [
      ui.hueGreen,
      ui.hueRed,
      ui.hueYellow,
      ui.hueBlue,
      ui.huePurple,
      ui.hueCornflowerBlue,
      ui.hueOrange,
      ui.colorGray,
      ui.hueCyan,
      ui.hueMagenta,
    ];
    final bg = widget.colors.bg;
    return ShadPopover(
      controller: _popover,
      popover: (context) => KeyedSubtree(
        key: ValueKey<String>('${widget.keyName}.picker'),
        child: WonkyColorPicker(
          value: bg == null ? null : WonkyColor.tryParse(bg),
          resetLabel: l.dvNoColor,
          resetIcon: LucideIcons.ban,
          themeColorsLabel: l.dvChipColors,
          themeColors: [
            for (final (i, c) in DvChipPalette.colors.indexed)
              WonkyThemeSwatch(
                color: WonkyColor.tryParse(c.bg!)!,
                name: names[i % names.length],
              ),
          ],
          onChanged: (c) {
            _popover.hide();
            widget.onChanged(
              c == null ? const DvChipColors() : chipColorsFor(c.hex),
            );
          },
        ),
      ),
      child: ShadTooltip(
        builder: (_) => Text(widget.label),
        child: ShadIconButton.ghost(
          key: ValueKey<String>(widget.keyName),
          width: 28,
          height: 28,
          semanticLabel: widget.label,
          icon: _swatch(context, widget.colors),
          onPressed: _popover.toggle,
        ),
      ),
    );
  }
}

/// The chip colors for background [hex]: a palette pair keeps its text
/// color, any other background gets [chipTextColorFor].
DvChipColors chipColorsFor(String hex) {
  final h = hex.toUpperCase();
  for (final c in DvChipPalette.colors) {
    if (c.bg!.toUpperCase() == h) return c;
  }
  return DvChipColors(bg: h, fg: chipTextColorFor(h));
}

/// A readable text color of the same hue for chip background [bgHex]: dark
/// (lightness 22 %) on light backgrounds, light (94 %) on dark ones.
String chipTextColorFor(String bgHex) {
  final c = hexToColor(bgHex) ?? const Color(0xFFE8EAED);
  final hsl = HSLColor.fromColor(c.withValues(alpha: 1));
  final dark = c.computeLuminance() > 0.35;
  final fg = hsl
      .withSaturation(hsl.saturation.clamp(0, 0.8))
      .withLightness(dark ? 0.22 : 0.94)
      .toColor();
  String h(double v) =>
      (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${h(fg.r)}${h(fg.g)}${h(fg.b)}';
}
