import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';

/// "Protected cell or object" (03 §16, 04 §11.16): the write was blocked.
Future<void> showProtectedBlockedDialog(BuildContext context) async {
  final l = sheetsL10n(context);
  await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.protectBlockedTitle,
      description: l.protectBlockedBody,
      dialogKey: 'dialog.protectedBlocked',
      cancelId: 'ok',
      buttons: [DialogButtonSpec(id: 'ok', label: l.dialogOk, primary: true)],
    ),
  );
}

/// "Heads up!" (03 §16): a warning-only protection. Returns null when
/// cancelled, otherwise whether "Don't show this again for 5 minutes" is
/// checked.
Future<bool?> showProtectedWarningDialog(BuildContext context) async {
  final l = sheetsL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.protectWarningTitle,
      description: l.protectWarningBody,
      dialogKey: 'dialog.protectedWarning',
      fields: [CheckboxFieldSpec(id: 'snooze', label: l.protectWarningSnooze)],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        DialogButtonSpec(id: 'ok', label: l.dialogOk, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return r!.flag('snooze');
}

/// One editor of the file offered in the permissions dialog.
@immutable
class ProtectionEditorOption {
  const ProtectionEditorOption({
    required this.userId,
    required this.label,
    this.email,
  });

  /// Auth user UUID (lower case).
  final String userId;
  final String label;
  final String? email;
}

/// Who may edit a protection (07 §10.2 permissions dialog).
@immutable
class ProtectionPermissions {
  const ProtectionPermissions({
    required this.warningOnly,
    this.editors = const [],
    this.addEmails = const [],
  });

  final bool warningOnly;

  /// Editors besides the owner and the creator (user UUIDs).
  final List<String> editors;

  /// Emails typed into "Add editors" (resolved by the caller).
  final List<String> addEmails;
}

/// A protection another one can copy permissions from.
typedef ProtectionCopySource = ({
  String id,
  String label,
  List<String> editors,
});

/// `ProtectionPermissionsDialog` (07 §10.2): mode (show a warning /
/// restrict), who (only you / custom / copy from another protection), one
/// checkbox per editor of the file and an "Add editors" email field — the
/// who/editors fields only show for *Restrict*, the editor list only for
/// *Custom*. MCP-describable like a `WonkyDialogSpec`
/// (`dialog.protectionPermissions`, fields `mode`, `who`, `editor:<id>`,
/// `add`, buttons `cancel`/`ok`).
Future<ProtectionPermissions?> showProtectionPermissionsDialog(
  BuildContext context, {
  required bool sheet,
  required ProtectionPermissions initial,
  required List<ProtectionEditorOption> editors,
  List<ProtectionCopySource> copyFrom = const [],
  bool offline = false,
}) => showShadDialog<ProtectionPermissions>(
  context: context,
  builder: (_) => ProtectionPermissionsDialog(
    sheet: sheet,
    initial: initial,
    editors: editors,
    copyFrom: copyFrom,
    offline: offline,
  ),
);

class ProtectionPermissionsDialog extends StatefulWidget {
  const ProtectionPermissionsDialog({
    super.key,
    required this.sheet,
    required this.initial,
    required this.editors,
    this.copyFrom = const [],
    this.offline = false,
  });

  final bool sheet;
  final ProtectionPermissions initial;
  final List<ProtectionEditorOption> editors;
  final List<ProtectionCopySource> copyFrom;
  final bool offline;

  @override
  State<ProtectionPermissionsDialog> createState() =>
      _ProtectionPermissionsDialogState();
}

class _ProtectionPermissionsDialogState
    extends State<ProtectionPermissionsDialog>
    implements McpDescribableDialog {
  static const _key = 'dialog.protectionPermissions';
  late bool _warning = widget.initial.warningOnly;
  late String _who = widget.initial.editors.isEmpty ? 'onlyYou' : 'custom';
  late final Set<String> _selected = {
    for (final e in widget.initial.editors) e.toLowerCase(),
  };
  final TextEditingController _add = TextEditingController();
  ShellServices? _registeredIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    _add.dispose();
    super.dispose();
  }

  Map<String, String> _whoOptions(SheetsLocalizations l) => {
    'onlyYou': l.protectPermOnlyYou,
    'custom': l.protectPermCustom,
    for (final c in widget.copyFrom) 'copy:${c.id}': l.protectPermCopy(c.label),
  };

  ProtectionPermissions _result() {
    if (_warning) return const ProtectionPermissions(warningOnly: true);
    final List<String> chosen;
    if (_who == 'onlyYou') {
      chosen = const [];
    } else if (_who.startsWith('copy:')) {
      final id = _who.substring(5);
      chosen = [
        for (final c in widget.copyFrom)
          if (c.id == id) ...c.editors,
      ];
    } else {
      chosen = [
        for (final e in widget.editors)
          if (_selected.contains(e.userId.toLowerCase())) e.userId,
      ];
    }
    final emails = _who == 'custom'
        ? [
            for (final part in _add.text.split(RegExp(r'[,;\s]+')))
              if (part.contains('@')) part.trim().toLowerCase(),
          ]
        : const <String>[];
    return ProtectionPermissions(
      warningOnly: false,
      editors: chosen,
      addEmails: emails,
    );
  }

  void _ok() => Navigator.of(context).pop(_result());
  void _cancel() => Navigator.of(context).pop();

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': widget.sheet
          ? l.protectPermissionsTitleSheet
          : l.protectPermissionsTitleRange,
      'fields': [
        {
          'id': 'mode',
          'label': l.protectPermMode,
          'type': 'select',
          'value': _warning ? 'warning' : 'restrict',
          'options': ['warning', 'restrict'],
        },
        if (!_warning)
          {
            'id': 'who',
            'label': l.protectPermWho,
            'type': 'select',
            'value': _who,
            'options': _whoOptions(l).keys.toList(),
          },
        if (!_warning && _who == 'custom') ...[
          for (final e in widget.editors)
            {
              'id': 'editor:${e.userId}',
              'label': e.label,
              'type': 'checkbox',
              'value': _selected.contains(e.userId.toLowerCase()),
            },
          {
            'id': 'add',
            'label': l.protectPermAddEditors,
            'type': 'text',
            'value': _add.text,
          },
        ],
      ],
      'buttons': [
        {'id': 'cancel', 'label': 'Cancel'},
        {'id': 'ok', 'label': 'Done'},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id == 'mode') {
      if (value != 'warning' && value != 'restrict') return false;
      setState(() => _warning = value == 'warning');
      return true;
    }
    if (id == 'who') {
      if (!_whoOptions(sheetsL10n(context)).containsKey(value)) return false;
      setState(() => _who = value! as String);
      return true;
    }
    if (id == 'add') {
      _add.text = '${value ?? ''}';
      return true;
    }
    if (id.startsWith('editor:') && value is bool) {
      final uid = id.substring(7).toLowerCase();
      setState(() => value ? _selected.add(uid) : _selected.remove(uid));
      return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'ok':
        _ok();
      case 'cancel':
        _cancel();
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final who = _whoOptions(l);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
      child: ShadDialog(
        key: const ValueKey<String>(_key),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(
          widget.sheet
              ? l.protectPermissionsTitleSheet
              : l.protectPermissionsTitleRange,
        ),
        description: Text(
          widget.offline
              ? '${l.protectAdvisory}\n\n${l.protectEditorsOffline}'
              : l.protectAdvisory,
        ),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('$_key.cancel'),
            onPressed: _cancel,
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('$_key.ok'),
            onPressed: _ok,
            child: Text(la.actionDone),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadRadioGroup<bool>(
                  key: ValueKey<String>('$_key.mode.$_warning'),
                  initialValue: _warning,
                  onChanged: (v) => setState(() => _warning = v ?? false),
                  items: [
                    ShadRadio(
                      key: const ValueKey<String>('$_key.mode.warning'),
                      value: true,
                      label: Text(l.protectPermWarning),
                    ),
                    ShadRadio(
                      key: const ValueKey<String>('$_key.mode.restrict'),
                      value: false,
                      label: Text(l.protectPermRestrict),
                    ),
                  ],
                ),
                if (!_warning) ...[
                  const SizedBox(height: 14),
                  Text(l.protectPermWho, style: theme.textTheme.small),
                  const SizedBox(height: 6),
                  ShadSelect<String>(
                    key: const ValueKey<String>('$_key.who'),
                    initialValue: _who,
                    options: [
                      for (final o in who.entries)
                        ShadOption(value: o.key, child: Text(o.value)),
                    ],
                    selectedOptionBuilder: (context, v) => Text(who[v] ?? v),
                    onChanged: (v) {
                      if (v != null) setState(() => _who = v);
                    },
                  ),
                ],
                if (!_warning && _who == 'custom') ...[
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final e in widget.editors)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: ShadCheckbox(
                                key: ValueKey<String>(
                                  '$_key.editor:${e.userId}',
                                ),
                                value: _selected.contains(
                                  e.userId.toLowerCase(),
                                ),
                                onChanged: (v) => setState(
                                  () => v
                                      ? _selected.add(e.userId.toLowerCase())
                                      : _selected.remove(
                                          e.userId.toLowerCase(),
                                        ),
                                ),
                                label: Text(
                                  e.email == null || e.email == e.label
                                      ? e.label
                                      : '${e.label} (${e.email})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(l.protectPermAddEditors, style: theme.textTheme.small),
                  const SizedBox(height: 6),
                  ShadInput(
                    key: const ValueKey<String>('$_key.add'),
                    controller: _add,
                    placeholder: Text(l.protectPermAddEditorsHint),
                    onSubmitted: (_) => _ok(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Offers to share the spreadsheet with people typed into "Add editors"
/// who can't edit it yet (07 §10.2). True: share them as editors.
Future<bool> showProtectionInviteDialog(
  BuildContext context,
  String names,
) async {
  final l = sheetsL10n(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.protectInviteTitle,
      description: l.protectInviteBody(names),
      dialogKey: 'dialog.protectionInvite',
      cancelId: 'skip',
      buttons: [
        DialogButtonSpec(id: 'skip', label: l.protectInviteSkip),
        DialogButtonSpec(
          id: 'share',
          label: l.protectInviteShare,
          primary: true,
        ),
      ],
    ),
  );
  return r?.buttonId == 'share';
}
