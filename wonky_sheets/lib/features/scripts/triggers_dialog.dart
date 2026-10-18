import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource, Role;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../history/change_labels.dart';
import '../../l10n/sheets_l10n.dart';
import '../data_tools/mcp_dialog.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'runtime/session_workbook_access.dart';
import 'script_project.dart';
import 'script_service.dart';
import 'script_widgets.dart';

/// Installable trigger events (09 §14.6; `ScriptTrigger.kind`).
const triggerEvents = ['timeDriven', 'onEdit', 'onChange', 'installableOnOpen'];

/// Schedule types of time-driven triggers (`TimeTriggerBuilder`).
const triggerScheduleTypes = [
  'minutes',
  'hours',
  'days',
  'weeks',
  'monthly',
  'once',
];

/// A trigger from the *Add trigger* form.
@immutable
class TriggerDraft {
  const TriggerDraft({
    required this.functionName,
    required this.event,
    this.schedule,
    this.options,
  });

  final String functionName;
  final String event;
  final Map<String, Object?>? schedule;
  final Map<String, Object?>? options;
}

/// Label of a trigger event.
String triggerEventLabel(SheetsLocalizations l, String event) =>
    switch (event) {
      'timeDriven' => l.triggerEventTime,
      'onEdit' => l.triggerEventEdit,
      'onChange' => l.triggerEventChange,
      'installableOnOpen' => l.triggerEventOpen,
      _ => event,
    };

/// One-line summary of a schedule ("Every 5 minutes", "Daily at 9:00").
String triggerScheduleSummary(
  SheetsLocalizations l,
  Map<String, Object?>? schedule,
) {
  if (schedule == null) return '';
  final n = (schedule['interval'] as num?)?.toInt() ?? 1;
  final hour = (schedule['atHour'] as num?)?.toInt() ?? 0;
  return switch (schedule['type']) {
    'minutes' => l.triggerEveryMinutes(n),
    'hours' => l.triggerEveryHours(n),
    'days' => l.triggerEveryDays(n, hour),
    'weeks' => l.triggerEveryWeeks(
      n,
      _weekday(l, (schedule['weekday'] as num?)?.toInt() ?? 1),
      hour,
    ),
    'monthly' => l.triggerMonthly(
      (schedule['monthDay'] as num?)?.toInt() ?? 1,
      hour,
    ),
    'once' => l.triggerOnce('${schedule['at'] ?? ''}'),
    _ => '',
  };
}

String _weekday(SheetsLocalizations l, int d) => switch (d) {
  1 => l.weekdayMonday,
  2 => l.weekdayTuesday,
  3 => l.weekdayWednesday,
  4 => l.weekdayThursday,
  5 => l.weekdayFriday,
  6 => l.weekdaySaturday,
  _ => l.weekdaySunday,
};

Map<String, Object?>? _json(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return (jsonDecode(raw) as Map).cast<String, Object?>();
  } on Object {
    return null;
  }
}

bool _isOwner(SheetEditorController ed) => ed.itemRole >= Role.owner;

/// The trigger rows the user sees: their own; owners see all (09 §14.6).
List<GenericRecord> visibleTriggers(SheetEditorController ed) => [
  for (final t in ScriptProjectRows.triggers(ed.model))
    if (_isOwner(ed) ||
        '${t.columns[ScriptCols.runAsUserId]}' == ed.session.userId)
      t,
];

/// JSON for MCP (`sheets.script.openTriggers` without a dialog).
List<Map<String, Object?>> describeTriggers(SheetEditorController ed) => [
  for (final t in visibleTriggers(ed))
    {
      'triggerId': t.id,
      'functionName': t.columns[ScriptCols.functionName],
      'event': t.columns[ScriptCols.kind],
      'schedule': _json(t.columns[ScriptCols.scheduleJson]),
      'enabled': t.columns[ScriptCols.enabled] != false,
      'runAsUserId': t.columns[ScriptCols.runAsUserId],
      'options': _json(t.columns[ScriptCols.optionsJson]),
    },
];

/// Creates a trigger as part of [ctx]'s undo step (`ModelTriggerStore`
/// validates the event and schedule and enforces the per-user limit).
String addTrigger(
  CommandContext ctx,
  SheetEditorController ed, {
  required String functionName,
  required String event,
  Map<String, Object?>? schedule,
  Map<String, Object?>? options,
}) {
  final access = SessionWorkbookAccess(ed, ctx: ctx);
  final store = ModelTriggerStore(
    access,
    userId: ed.session.userId,
    isOwner: _isOwner(ed),
  );
  final info = store.create(
    functionName,
    event,
    event == 'timeDriven' ? schedule : null,
  );
  if (options != null && options.isNotEmpty) {
    ed.apply(
      ctx,
      GenericRowWrite(SheetsTables.scriptTrigger, info.uid, {
        ScriptCols.optionsJson: jsonEncode(options),
      }, label: SheetsChangeLabels.addTrigger),
    );
  }
  return info.uid;
}

/// Updates columns of the trigger [id]; returns an error message or null.
String? updateTrigger(
  CommandContext ctx,
  SheetEditorController ed,
  String id,
  Map<String, Object?> columns,
) {
  final row = ScriptProjectRows.triggers(
    ed.model,
  ).where((t) => t.id == id).firstOrNull;
  if (row == null) return ed.l10n.triggerNotFound;
  if (!_isOwner(ed) &&
      '${row.columns[ScriptCols.runAsUserId]}' != ed.session.userId) {
    return ed.l10n.triggerNotYours;
  }
  if (columns.isEmpty) return null;
  ed.apply(
    ctx,
    GenericRowWrite(
      SheetsTables.scriptTrigger,
      id,
      columns,
      label: SheetsChangeLabels.editTrigger,
    ),
  );
  return null;
}

/// Deletes the trigger [id]; returns an error message or null.
String? deleteTrigger(CommandContext ctx, SheetEditorController ed, String id) {
  final store = ModelTriggerStore(
    SessionWorkbookAccess(ed, ctx: ctx),
    userId: ed.session.userId,
    isOwner: _isOwner(ed),
  );
  try {
    store.delete(id);
    return null;
  } on ArgumentError {
    return ed.l10n.triggerNotFound;
  } on StateError {
    return ed.l10n.triggerNotYours;
  }
}

/// The *Add trigger* form (09 §14.6) as a `WonkyDialogSpec`.
Future<TriggerDraft?> showAddTriggerDialog(
  BuildContext context,
  SheetEditorController ed,
) async {
  final l = sheetsL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final fns = [
    for (final f in ScriptService.of(ed).exports.runnableFunctions) f.name,
  ];
  if (fns.isEmpty) {
    ed.services.toasts.show(l.scriptNoRunnableFunctions);
    return null;
  }
  String? intIn(String v, int min, int max) {
    final n = int.tryParse(v.trim());
    return n == null || n < min || n > max ? l.triggerInvalidNumber : null;
  }

  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.triggerAddTitle,
      dialogKey: 'dialog.addTrigger',
      width: 460,
      fields: [
        SelectFieldSpec(
          id: 'function',
          label: l.triggerFunction,
          options: {for (final f in fns) f: f},
          initial: fns.first,
        ),
        SelectFieldSpec(
          id: 'event',
          label: l.triggerEvent,
          options: {for (final e in triggerEvents) e: triggerEventLabel(l, e)},
          initial: 'timeDriven',
        ),
        SelectFieldSpec(
          id: 'type',
          label: l.triggerScheduleType,
          options: {
            'minutes': l.triggerTypeMinutes,
            'hours': l.triggerTypeHours,
            'days': l.triggerTypeDays,
            'weeks': l.triggerTypeWeeks,
            'monthly': l.triggerTypeMonthly,
            'once': l.triggerTypeOnce,
          },
          initial: 'hours',
        ),
        TextFieldSpec(
          id: 'interval',
          label: l.triggerInterval,
          initial: '1',
          validator: (v) => intIn(v, 1, 30),
        ),
        TextFieldSpec(
          id: 'atHour',
          label: l.triggerAtHour,
          initial: '9',
          validator: (v) => intIn(v, 0, 23),
        ),
        SelectFieldSpec(
          id: 'weekday',
          label: l.triggerWeekday,
          options: {for (var d = 1; d <= 7; d++) '$d': _weekday(l, d)},
          initial: '1',
        ),
        TextFieldSpec(
          id: 'monthDay',
          label: l.triggerMonthDay,
          initial: '1',
          validator: (v) => intIn(v, 1, 31),
        ),
        TextFieldSpec(
          id: 'at',
          label: l.triggerAt,
          placeholder: '2026-12-24T09:00',
          validator: (v) => v.trim().isEmpty || DateTime.tryParse(v) != null
              ? null
              : l.triggerInvalidDate,
        ),
        SelectFieldSpec(
          id: 'notify',
          label: l.triggerNotify,
          options: {
            'immediately': l.triggerNotifyImmediately,
            'daily': l.triggerNotifyDaily,
            'never': l.triggerNotifyNever,
          },
          initial: 'daily',
        ),
        CheckboxFieldSpec(id: 'fireForMcp', label: l.triggerFireForMcp),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        DialogButtonSpec(id: 'save', label: l.dialogSave, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'save') return null;
  final event = r!.text('event');
  final type = r.text('type');
  Map<String, Object?>? schedule;
  if (event == 'timeDriven') {
    schedule = {
      'type': type,
      if (type != 'once') 'interval': int.tryParse(r.text('interval')) ?? 1,
      if (type == 'days' || type == 'weeks' || type == 'monthly')
        'atHour': int.tryParse(r.text('atHour')) ?? 0,
      if (type == 'weeks') 'weekday': int.tryParse(r.text('weekday')) ?? 1,
      if (type == 'monthly') 'monthDay': int.tryParse(r.text('monthDay')) ?? 1,
      if (type == 'once')
        'at': (DateTime.tryParse(r.text('at').trim()) ?? DateTime.now())
            .toUtc()
            .toIso8601String(),
    };
  }
  return TriggerDraft(
    functionName: r.text('function'),
    event: event,
    schedule: schedule,
    options: {
      'notify': r.text('notify'),
      if (event == 'onEdit' || event == 'onChange')
        'fireForMcp': r.flag('fireForMcp'),
    },
  );
}

/// The Triggers dialog (09 §14.6): the user's installable triggers (owners
/// see everyone's) with event, schedule, enabled switch and delete; *Add
/// trigger* opens the form. Every change is a command (undoable).
Future<void> showTriggersDialog(
  BuildContext context,
  SheetEditorController editor,
) => showShadDialog<void>(
  context: context,
  builder: (_) => TriggersDialog(editor: editor),
);

class TriggersDialog extends StatefulWidget {
  const TriggersDialog({super.key, required this.editor});

  final SheetEditorController editor;

  @override
  State<TriggersDialog> createState() => _TriggersDialogState();
}

class _TriggersDialogState extends State<TriggersDialog>
    with McpDialogState<TriggersDialog> {
  SheetEditorController get ed => widget.editor;
  late final ScriptService _svc = ScriptService.of(ed);

  @override
  void initState() {
    super.initState();
    _svc.addListener(_changed);
  }

  @override
  void dispose() {
    _svc.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _invoke(String id, [Map<String, Object?> args = const {}]) =>
      ed.invokeCommand(id, args, InvocationSource.ui);

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.cmdScriptOpenTriggers,
      'fields': [
        for (final t in visibleTriggers(ed))
          {
            'id': 'enabled.${t.id}',
            'label':
                '${t.columns[ScriptCols.functionName]} · '
                '${triggerEventLabel(l, '${t.columns[ScriptCols.kind]}')}',
            'type': 'checkbox',
            'value': t.columns[ScriptCols.enabled] != false,
          },
      ],
      'buttons': [
        {'id': 'add', 'label': l.triggerAdd},
        {'id': 'close', 'label': l.dialogClose},
      ],
      'triggers': describeTriggers(ed),
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (!id.startsWith('enabled.') || value is! bool) return false;
    unawaited(
      _invoke('sheets.script.updateTrigger', {
        'triggerId': id.substring(8),
        'enabled': value,
      }),
    );
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'add':
        unawaited(_invoke('sheets.script.addTrigger'));
      case 'close':
        Navigator.of(context).pop();
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final rows = visibleTriggers(ed);
    final owner = _isOwner(ed);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.triggers'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.cmdScriptOpenTriggers),
        description: Text(l.triggersDescription),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.triggers.close'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.dialogClose),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.triggers.add'),
            leading: const Icon(LucideIcons.plus, size: 16),
            onPressed: ed.canEdit
                ? () => _invoke('sheets.script.addTrigger')
                : null,
            child: Text(l.triggerAdd),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 420),
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l.triggersEmpty,
                    key: const ValueKey<String>('dialog.triggers.empty'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.muted,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      Container(height: 1, color: theme.colorScheme.border),
                  itemBuilder: (context, i) =>
                      _row(context, rows[i], showOwner: owner),
                ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    GenericRecord t, {
    required bool showOwner,
  }) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final event = '${t.columns[ScriptCols.kind]}';
    final schedule = triggerScheduleSummary(
      l,
      _json(t.columns[ScriptCols.scheduleJson]),
    );
    final enabled = t.columns[ScriptCols.enabled] != false;
    final mine = '${t.columns[ScriptCols.runAsUserId]}' == ed.session.userId;
    return Padding(
      key: ValueKey<String>('dialog.triggers.row.${t.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            event == 'timeDriven' ? LucideIcons.alarmClock : LucideIcons.zap,
            size: 16,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.columns[ScriptCols.functionName]}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small.copyWith(
                    fontFamily: WonkyTheme.monoFamily,
                  ),
                ),
                Text(
                  [
                    triggerEventLabel(l, event),
                    if (schedule.isNotEmpty) schedule,
                    if (showOwner && !mine) l.triggerOwnerOther,
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ),
          ShadTooltip(
            builder: (_) =>
                Text(enabled ? l.triggerEnabled : l.triggerDisabled),
            child: ShadSwitch(
              key: ValueKey<String>('dialog.triggers.enabled.${t.id}'),
              value: enabled,
              onChanged: ed.canEdit
                  ? (v) => _invoke('sheets.script.updateTrigger', {
                      'triggerId': t.id,
                      'enabled': v,
                    })
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          scriptIconButton(
            key: ValueKey<String>('dialog.triggers.delete.${t.id}'),
            icon: LucideIcons.trash2,
            tooltip: l.triggerDelete,
            onPressed: ed.canEdit
                ? () => _invoke('sheets.script.deleteTrigger', {
                    'triggerId': t.id,
                  })
                : null,
          ),
        ],
      ),
    );
  }
}
