import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../data/api.dart';
import '../../data/models_ext.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/dialogs.dart';
import '../../shell/form_dialog.dart';
import '../../shell/shell_scope.dart';
import '../../shell/shell_services.dart';

/// Picked destination of the Move dialog (null folder = My Drive root).
class MoveTarget {
  const MoveTarget(this.folderUuid);
  final UuidValue? folderUuid;
}

/// Options of "Make a copy".
class CopyRequest {
  const CopyRequest({
    required this.name,
    required this.folderUuid,
    this.copyComments = false,
    this.copySharing = false,
  });

  final String name;
  final UuidValue? folderUuid;
  final bool copyComments;
  final bool copySharing;
}

Future<String?> showRenameDialog(
  BuildContext context,
  ShellServices s,
  DriveItemView item,
) {
  final l = WonkyAppLocalizations.of(context);
  return showTextInputDialog(
    context,
    title: l.renameTitle,
    label: l.renameLabel,
    confirmLabel: l.actionOk,
    initial: item.name,
    dialogKey: 'dialog.rename',
    validator: itemNameValidator(l),
  );
}

Future<String?> showNewFolderDialog(BuildContext context, ShellServices s) {
  final l = WonkyAppLocalizations.of(context);
  return showTextInputDialog(
    context,
    title: l.newFolderTitle,
    label: l.newFolderLabel,
    confirmLabel: l.actionCreate,
    initial: l.untitledFolder,
    dialogKey: 'dialog.newFolder',
    validator: itemNameValidator(l),
  );
}

Future<CopyRequest?> showCopyDialog(
  BuildContext context,
  ShellServices s,
  DriveItemView item,
) async {
  final l = WonkyAppLocalizations.of(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.copyTitle,
      dialogKey: 'dialog.copy',
      fields: [
        TextFieldSpec(
          id: 'name',
          label: l.copyName,
          initial: l.copyOfName(item.name),
          validator: itemNameValidator(l),
        ),
        CheckboxFieldSpec(id: 'copyComments', label: l.copyComments),
        CheckboxFieldSpec(id: 'copySharing', label: l.copySharing),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.actionCancel),
        DialogButtonSpec(id: 'ok', label: l.copyAction, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'ok') return null;
  return CopyRequest(
    name: r!.text('name').trim(),
    folderUuid: item.parentUuid,
    copyComments: r.flag('copyComments'),
    copySharing: r.flag('copySharing'),
  );
}

Future<bool> confirmDeleteForever(BuildContext context, int count) {
  final l = WonkyAppLocalizations.of(context);
  return confirmDialog(
    context,
    title: l.deleteForeverTitle(count),
    description: l.deleteForeverBody,
    confirmLabel: l.deleteForeverAction,
    destructive: true,
  );
}

Future<bool> confirmEmptyTrash(BuildContext context) {
  final l = WonkyAppLocalizations.of(context);
  return confirmDialog(
    context,
    title: l.emptyTrashTitle,
    description: l.emptyTrashBody,
    confirmLabel: l.emptyTrashAction,
    destructive: true,
  );
}

/// The "Move to…" folder browser (suite 05 §3.2): breadcrumb, sub-folders,
/// inline "New folder", disabled targets without edit permission (and the
/// moved folders themselves).
Future<MoveTarget?> showMoveDialog(
  BuildContext context,
  ShellServices s,
  List<DriveItemView> items, {
  String? title,
  String? actionLabel,
}) => showShadDialog<MoveTarget>(
  context: context,
  builder: (_) => _MoveDialog(
    services: s,
    items: items,
    title: title,
    actionLabel: actionLabel,
  ),
);

class _MoveDialog extends StatefulWidget {
  const _MoveDialog({
    required this.services,
    required this.items,
    this.title,
    this.actionLabel,
  });

  final ShellServices services;
  final List<DriveItemView> items;
  final String? title;
  final String? actionLabel;

  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  DriveItemView? _folder;
  List<DriveItemView> _path = const [];
  List<DriveItemView> _children = const [];
  bool _loading = true;
  Object? _error;
  bool _creating = false;
  final _newName = TextEditingController();

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    final parent = widget.items.length == 1
        ? widget.items.single.parentUuid
        : null;
    _open(parent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = ShellScope.maybeOf(context);
    _registeredIn = services;
    if (services != null && !services.openDialogs.contains(this)) {
      services.openDialogs.add(this);
    }
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    _newName.dispose();
    super.dispose();
  }

  Future<void> _open(UuidValue? folderUuid) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folder = folderUuid == null ? null : await s.drive.get(folderUuid);
      final path = folderUuid == null
          ? const <DriveItemView>[]
          : await s.drive.path(folderUuid);
      final page = await s.drive.list(
        folderUuid: folderUuid,
        filter: DriveListFilter(
          view: DriveView.folder,
          kinds: [DriveItemKind.folder],
        ),
        sort: DriveSort(field: DriveSortField.name, descending: false),
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _folder = folder;
        _path = path;
        _children = [
          for (final c in page.items)
            if (c.isFolder && !c.isTrashed) c,
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool _isMoving(DriveItemView f) => widget.items.any((i) => i.uuid == f.uuid);

  bool get _canDropHere {
    final f = _folder;
    if (f != null && (!f.canEdit || _isMoving(f))) return false;
    if (_path.any(_isMoving)) return false;
    // Already there?
    return !widget.items.every((i) => i.parentUuid == f?.uuid);
  }

  Future<void> _createFolder() async {
    final l = WonkyAppLocalizations.of(context);
    final name = _newName.text.trim();
    if (name.isEmpty) return;
    try {
      // Through the command: undoable and visible to agents (CQ-54).
      final result = await s.dispatcher.invoke(
        'shell.drive.newFolder',
        args: {'name': name, 'parentUuid': _folder?.uuid.uuid},
        source: InvocationSource.ui,
      );
      final data = result.data;
      final uuid = data is Map ? data['uuid'] : null;
      if (!mounted || uuid is! String) return;
      _newName.clear();
      setState(() => _creating = false);
      await _open(UuidValue.fromString(uuid));
    } catch (e) {
      s.toasts.error(l.errorGeneric, description: errorMessage(e));
    }
  }

  @override
  Map<String, Object?> describe() => {
    'title': widget.title ?? 'Move',
    'fields': [
      {
        'id': 'folder',
        'label': 'Folder',
        'type': 'select',
        'value': _folder?.uuid.uuid,
        'options': [null, for (final c in _children) c.uuid.uuid],
      },
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
      {
        'id': 'move',
        'label': widget.actionLabel ?? 'Move here',
        'enabled': _canDropHere,
      },
    ],
  };

  @override
  bool setField(String id, Object? value) {
    if (id != 'folder') return false;
    _open(value == null ? null : UuidValue.fromString('$value'));
    return true;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'cancel') {
      Navigator.of(context).pop();
      return true;
    }
    if (buttonId == 'move' && _canDropHere) {
      Navigator.of(context).pop(MoveTarget(_folder?.uuid));
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final title =
        widget.title ??
        (widget.items.length == 1
            ? l.moveTitleOne(widget.items.single.name)
            : l.moveTitleMany(widget.items.length));
    return ShadDialog(
      key: const ValueKey<String>('dialog.move'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(title),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('dialog.move.confirm'),
          enabled: _canDropHere && !_loading,
          onPressed: () => Navigator.of(context).pop(MoveTarget(_folder?.uuid)),
          child: Text(widget.actionLabel ?? l.moveHere),
        ),
      ],
      child: SizedBox(
        width: 460,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (_folder != null)
                  ShadIconButton.ghost(
                    width: 28,
                    height: 28,
                    iconSize: 16,
                    semanticLabel: l.actionBack,
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => _open(_folder!.parentUuid),
                  ),
                Expanded(
                  child: ShadBreadcrumb(
                    children: [
                      ShadBreadcrumbLink(
                        onPressed: () => _open(null),
                        child: Text(l.navMyDrive),
                      ),
                      for (final p in _path)
                        ShadBreadcrumbLink(
                          onPressed: () => _open(p.uuid),
                          child: Text(p.name),
                        ),
                      if (_folder != null) Text(_folder!.name),
                    ],
                  ),
                ),
                ShadTooltip(
                  builder: (_) => Text(l.cmdNewFolder),
                  child: ShadIconButton.ghost(
                    key: const ValueKey<String>('dialog.move.newFolder'),
                    width: 28,
                    height: 28,
                    iconSize: 16,
                    semanticLabel: l.cmdNewFolder,
                    icon: const Icon(LucideIcons.folderPlus),
                    onPressed: (_folder?.canEdit ?? true)
                        ? () => setState(() => _creating = true)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_creating)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(
                            LogicalKeyboardKey.escape,
                          ): () =>
                              setState(() => _creating = false),
                        },
                        child: ShadInput(
                          controller: _newName,
                          autofocus: true,
                          placeholder: Text(l.newFolderLabel),
                          onSubmitted: (_) => _createFolder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ShadButton(
                      onPressed: _createFolder,
                      child: Text(l.actionCreate),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loading
                    ? const Center(child: ShadSpinner())
                    : _error != null
                    ? Center(
                        child: Text(
                          errorMessage(_error!),
                          style: theme.textTheme.muted,
                        ),
                      )
                    : _children.isEmpty
                    ? Center(
                        child: Text(
                          l.moveNoFolders,
                          style: theme.textTheme.muted,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(4),
                        children: [
                          for (final f in _children)
                            ShadButton.ghost(
                              key: ValueKey<String>(
                                'dialog.move.folder.${f.uuid.uuid}',
                              ),
                              enabled: !_isMoving(f),
                              mainAxisAlignment: MainAxisAlignment.start,
                              leading: Icon(
                                LucideIcons.folder,
                                size: 16,
                                color: f.canEdit
                                    ? null
                                    : theme.colorScheme.mutedForeground,
                              ),
                              trailing: const Icon(
                                LucideIcons.chevronRight,
                                size: 14,
                              ),
                              onPressed: () => _open(f.uuid),
                              child: Expanded(
                                child: Text(
                                  f.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: f.canEdit
                                        ? null
                                        : theme.colorScheme.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            if (_folder != null && !_folder!.canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.moveNoPermission,
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
