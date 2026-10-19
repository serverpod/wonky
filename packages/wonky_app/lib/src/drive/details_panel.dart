import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_ui/wonky_ui.dart';

import '../branding/product_icon.dart';
import '../activity/activity_feed.dart';
import '../data/api.dart';
import '../data/models_ext.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/shell_services.dart';
import 'drive_format.dart';

/// The details side panel (suite 05 §3.1, `i`): type, owner, location,
/// sharing summary, dates, editable description and the activity feed.
class DriveDetailsPanel extends StatefulWidget {
  const DriveDetailsPanel({
    super.key,
    required this.services,
    required this.item,
  });

  final ShellServices services;
  final DriveItemView? item;

  @override
  State<DriveDetailsPanel> createState() => _DriveDetailsPanelState();
}

class _DriveDetailsPanelState extends State<DriveDetailsPanel> {
  Future<List<DriveItemView>>? _path;
  final _desc = TextEditingController();
  final _descFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load(widget.item);
  }

  @override
  void didUpdateWidget(DriveDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final item = widget.item;
    if (item?.uuid != oldWidget.item?.uuid) {
      _load(item);
    } else if (item != null &&
        item.description != oldWidget.item?.description &&
        !_descFocus.hasFocus) {
      // Changed elsewhere (undo, another device): show it unless the user
      // is typing.
      _desc.text = item.description ?? '';
    }
  }

  @override
  void dispose() {
    _desc.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _load(DriveItemView? item) {
    if (item == null) return;
    _desc.text = item.description ?? '';
    _path = widget.services.drive.path(item.uuid);
  }

  /// Saves the description through `shell.drive.setDescription`, so it is
  /// undoable and visible to agents (08 §1.1; CQ-54).
  Future<void> _saveDescription(DriveItemView item) async {
    final text = _desc.text.trim();
    if (text == (item.description ?? '')) return;
    try {
      await widget.services.dispatcher.invoke(
        'shell.drive.setDescription',
        args: {'uuid': item.uuid.uuid, 'description': text},
        source: InvocationSource.ui,
      );
    } catch (e) {
      widget.services.toasts.error(
        widget.services.l10n?.errorGeneric ?? 'Error',
        description: errorMessage(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final item = widget.item;
    if (item == null) {
      return WonkyEmptyState(
        illustration: EmptyIllustration.folder,
        title: l.detailsNothingSelected,
        size: 80,
      );
    }
    final date = intl.DateFormat.yMMMd().add_jm();
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.muted.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.canvas,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: DriveKindIcon.item(item, size: 48)),
        ),
        const SizedBox(height: 12),
        Text(item.name, style: theme.textTheme.large),
        const SizedBox(height: 12),
        row(l.detailsType, Text(describeKind(l, item.kind))),
        row(
          l.detailsOwner,
          Row(
            children: [
              WonkyAvatar(
                name: item.owner.displayName,
                color: parseHexColor(item.owner.avatarColor),
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.owner.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        row(
          l.detailsLocation,
          FutureBuilder<List<DriveItemView>>(
            future: _path,
            builder: (context, snap) {
              final p = snap.data;
              final text = p == null
                  ? '…'
                  : [l.navMyDrive, ...p.map((x) => x.name)].join(' › ');
              return Text(text, overflow: TextOverflow.ellipsis);
            },
          ),
        ),
        row(
          l.detailsAccess,
          Text(item.shared ? l.detailsShared : l.detailsPrivate),
        ),
        row(l.detailsRole, Text(roleName(l, item.role))),
        row(l.detailsModified, Text(date.format(item.modifiedAt.toLocal()))),
        if (item.lastOpenedAt != null)
          row(l.detailsOpened, Text(date.format(item.lastOpenedAt!.toLocal()))),
        row(l.detailsCreated, Text(date.format(item.createdAt.toLocal()))),
        if (!item.isFolder)
          row(l.columnSize, Text(formatBytes(item.sizeBytes))),
        row(
          l.detailsDescription,
          item.canEdit
              ? Focus(
                  focusNode: _descFocus,
                  onFocusChange: (f) {
                    if (!f) _saveDescription(item);
                  },
                  child: ShadTextarea(
                    key: const ValueKey<String>('details.description'),
                    controller: _desc,
                    placeholder: Text(l.detailsDescriptionHint),
                    minHeight: 60,
                  ),
                )
              : Text(item.description ?? '—'),
        ),
        const SizedBox(height: 8),
        Text(
          l.detailsActivity,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ActivityFeed(
          key: ValueKey<String>('details.activity.${item.uuid.uuid}'),
          services: widget.services,
          itemUuid: item.uuid,
        ),
      ],
    );
  }
}

String roleName(WonkyAppLocalizations l, AccessRole r) => switch (r) {
  AccessRole.viewer => l.roleViewer,
  AccessRole.commenter => l.roleCommenter,
  AccessRole.editor => l.roleEditor,
  AccessRole.owner => l.roleOwner,
};

/// Keeps a details panel bound to the current selection.
class SelectionDetailsPanel extends StatelessWidget {
  const SelectionDetailsPanel({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<DriveItemView>>(
        valueListenable: services.driveSelection,
        builder: (context, sel, _) => ValueListenableBuilder<DriveItemView?>(
          valueListenable: services.currentItem,
          builder: (context, cur, _) {
            final item = sel.length == 1
                ? sel.single
                : (sel.isEmpty ? (cur ?? services.currentFolder.value) : null);
            return DriveDetailsPanel(
              key: ValueKey(item?.uuid.uuid),
              services: services,
              item: item,
            );
          },
        ),
      );
}
