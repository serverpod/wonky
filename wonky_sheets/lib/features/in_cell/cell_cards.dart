import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart' show DriveKindIcon;
import 'package:wonky_client/wonky_client.dart' show DriveItemKind;

import 'package:wonky_sheets_core/formula.dart' show CellPos;

import 'smart_chips.dart';
import '../links/link_dialog.dart' show linkTargetLabel;
import '../../l10n/sheets_l10n.dart';
import '../../theme/sheets_tokens.dart';
import 'cell_popups.dart';
import 'in_cell_controller.dart';

/// What the info card of a cell shows (03 §14.4–14.8).
@immutable
class CellInfo {
  const CellInfo({
    required this.sheetId,
    required this.row,
    required this.col,
    this.note,
    this.link,
    this.errorTitle,
    this.error,
    this.invalid,
    this.help,
    this.person,
    this.file,
  });

  /// The people smart chip of the cell (03 §14.3).
  final PersonChip? person;

  /// The file smart chip of the cell (03 §14.3).
  final FileChip? file;

  final String sheetId;
  final int row;
  final int col;
  final String? note;
  final String? link;

  /// The error literal (`#DIV/0!`) and its message.
  final String? errorTitle;
  final String? error;

  /// Data validation message of an invalid value.
  final String? invalid;

  /// Data validation help text of the selected cell.
  final String? help;

  bool get isEmpty =>
      note == null &&
      link == null &&
      errorTitle == null &&
      invalid == null &&
      help == null &&
      person == null &&
      file == null;
}

/// Places [child] next to [cell] inside [area] (below, or above when there
/// is no room), [width] wide.
Widget anchoredToCell({
  Key? key,
  required Rect cell,
  required Size area,
  required double width,
  required double maxHeight,
  required Widget child,
}) {
  final w = math.min(width, math.max(120.0, area.width - 8));
  final left = cell.left
      .clamp(4.0, math.max(4.0, area.width - w - 4))
      .toDouble();
  final below = area.height - cell.bottom - 4;
  final above = cell.top - 4;
  final placeBelow = below >= math.min(maxHeight, 160) || below >= above;
  final h = math.max(60.0, math.min(maxHeight, placeBelow ? below : above));
  return Positioned(
    key: key,
    left: left,
    width: w,
    top: placeBelow ? cell.bottom + 2 : null,
    bottom: placeBelow ? null : area.height - cell.top + 2,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: h),
      child: child,
    ),
  );
}

/// Popover chrome shared by the cards and pickers.
class CellPopoverSurface extends StatelessWidget {
  const CellPopoverSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.popover,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: cs.popoverForeground),
        child: child,
      ),
    );
  }
}

/// The popovers and cards of [InCellController] inside the grid's stack.
class InCellOverlay extends StatelessWidget {
  const InCellOverlay({super.key, required this.controller});

  final InCellController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final ed = c.editor;
    return ListenableBuilder(
      listenable: Listenable.merge([
        c.popup,
        c.card,
        ed.scroll,
        ed.contentSignal,
      ]),
      builder: (context, _) {
        final g = ed.geometry;
        if (g == null) return const SizedBox.shrink();
        final area = g.size;
        final children = <Widget>[];
        final p = c.popup.value;
        if (p != null) {
          final rect = c.cellRect(p.sheetId, p.row, p.col);
          if (rect != null) {
            children.add(
              anchoredToCell(
                key: ValueKey<String>('sheets.cellPopup.${p.kind.name}'),
                cell: rect,
                area: area,
                width: p.kind == CellPopupKind.date
                    ? 290
                    : (p.kind == CellPopupKind.smartChip ? 300 : 260),
                maxHeight: p.kind == CellPopupKind.date ? 360 : 340,
                child: switch (p.kind) {
                  CellPopupKind.dropdown => DropdownPickerPopover(
                    controller: c,
                    popup: p,
                  ),
                  CellPopupKind.date => DatePickerPopover(
                    controller: c,
                    popup: p,
                  ),
                  CellPopupKind.note => NotePopover(controller: c, popup: p),
                  CellPopupKind.smartChip => SmartChipMenu(
                    controller: c,
                    popup: p,
                  ),
                },
              ),
            );
          }
        }
        final t = c.card.value;
        if (t != null && p == null) {
          final info = c.infoAt(t.sheetId, t.row, t.col, hover: t.hover);
          final rect = c.cellRect(t.sheetId, t.row, t.col);
          if (info != null && rect != null) {
            children.add(
              anchoredToCell(
                key: const ValueKey<String>('sheets.cellCard'),
                cell: rect,
                area: area,
                width: 320,
                maxHeight: 300,
                child: MouseRegion(
                  onEnter: (_) => c.setOverCard(true),
                  onExit: (_) => c.setOverCard(false),
                  child: CellInfoCard(controller: c, info: info),
                ),
              ),
            );
          }
        }
        if (children.isEmpty) return const SizedBox.shrink();
        return Positioned.fill(
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
  }
}

/// The hover / selected-cell card: link card (03 §14.4), note (§14.5),
/// error tooltip (§14.7, incl. `#SPILL!` §14.8), invalid data and help
/// text (07 §6.5).
class CellInfoCard extends StatelessWidget {
  const CellInfoCard({super.key, required this.controller, required this.info});

  final InCellController controller;
  final CellInfo info;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final tokens = GridPaintTokens.ofContext(context);
    final sections = <Widget>[];
    void add(Widget w) {
      if (sections.isNotEmpty) {
        sections.add(
          const ShadSeparator.horizontal(
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
        );
      }
      sections.add(w);
    }

    final title = theme.textTheme.small.copyWith(fontWeight: FontWeight.w600);
    final body = theme.textTheme.small.copyWith(fontSize: 12.5);
    if (info.errorTitle != null) {
      final hint = switch (info.errorTitle) {
        '#REF!' => l.errorHintRef,
        '#NAME?' => l.errorHintName,
        _ => null,
      };
      add(
        Column(
          key: const ValueKey<String>('sheets.cellCard.error'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.circleAlert,
                  size: 14,
                  color: tokens.errorTriangle,
                ),
                const SizedBox(width: 6),
                Text(
                  info.errorTitle == '#SPILL!'
                      ? l.spillTooltipTitle
                      : l.errorTooltipTitle,
                  style: title,
                ),
                const SizedBox(width: 6),
                Text(
                  info.errorTitle!,
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
            if (info.error != null) ...[
              const SizedBox(height: 4),
              Text(info.error!, style: body),
            ],
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint, style: theme.textTheme.muted.copyWith(fontSize: 12)),
            ],
          ],
        ),
      );
    }
    if (info.invalid != null) {
      add(
        Column(
          key: const ValueKey<String>('sheets.cellCard.invalid'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.triangleAlert,
                  size: 14,
                  color: tokens.invalidTriangle,
                ),
                const SizedBox(width: 6),
                Text(l.dvInvalidTooltipTitle, style: title),
              ],
            ),
            const SizedBox(height: 4),
            Text(info.invalid!, style: body),
          ],
        ),
      );
    }
    if (info.help != null) {
      add(
        Column(
          key: const ValueKey<String>('sheets.cellCard.help'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.cellInfoHelp, style: title),
            const SizedBox(height: 4),
            Text(info.help!, style: body),
          ],
        ),
      );
    }
    if (info.note != null) {
      add(
        Column(
          key: const ValueKey<String>('sheets.cellCard.note'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.cellInfoNote, style: title),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(info.note!, style: body),
              ),
            ),
          ],
        ),
      );
    }
    if (info.link != null) {
      add(LinkCardSection(controller: controller, info: info));
    }
    final person = info.person;
    if (person != null) {
      add(
        Row(
          key: const ValueKey<String>('sheets.cellCard.person'),
          children: [
            Icon(
              LucideIcons.user,
              size: 16,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    person.name,
                    style: title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    person.email,
                    style: body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ShadTooltip(
              builder: (_) => Text(l.smartChipCopyEmail),
              child: ShadIconButton.ghost(
                key: const ValueKey<String>('sheets.cellCard.person.copy'),
                width: 28,
                height: 28,
                iconSize: 14,
                semanticLabel: l.smartChipCopyEmail,
                icon: const Icon(LucideIcons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: person.email));
                  controller.editor.services.toasts.show(
                    l.smartChipEmailCopied,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    final file = info.file;
    if (file != null) {
      add(
        Row(
          key: const ValueKey<String>('sheets.cellCard.file'),
          children: [
            DriveKindIcon(switch (file.itemKind) {
              'spreadsheet' => DriveItemKind.spreadsheet,
              'folder' => DriveItemKind.folder,
              _ => DriveItemKind.document,
            }, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                file.name,
                style: title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ShadButton.ghost(
              key: const ValueKey<String>('sheets.cellCard.file.open'),
              size: ShadButtonSize.sm,
              onPressed: () => controller.editor.invokeCommand(
                'sheets.chip.openFile',
                {'uuid': file.uuid},
              ),
              child: Text(l.smartChipOpenFile),
            ),
          ],
        ),
      );
    }
    return CellPopoverSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: sections,
      ),
    );
  }
}

/// The link part of the card: the URL (opens it), *Copy link*, *Edit* and
/// *Remove link* (03 §14.4).
class LinkCardSection extends StatelessWidget {
  const LinkCardSection({
    super.key,
    required this.controller,
    required this.info,
  });

  final InCellController controller;
  final CellInfo info;

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final tokens = GridPaintTokens.ofContext(context);
    final ed = controller.editor;
    final url = info.link!;
    final internal = url.startsWith('#');
    Future<void> run(String id, [Map<String, Object?> args = const {}]) async {
      if (ed.activeSheetId == info.sheetId) {
        final sel = ed.selection.resolved;
        if (sel.activeRow != info.row || sel.activeCol != info.col) {
          ed.selection.selectCell(info.row, info.col);
        }
      }
      await ed.invokeCommand(id, args);
    }

    final cellA1 = CellPos(info.row, info.col).a1;
    return Column(
      key: const ValueKey<String>('sheets.cellCard.link'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              internal ? LucideIcons.sheet : LucideIcons.globe,
              size: 14,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                link: true,
                label: url,
                child: GestureDetector(
                  key: const ValueKey<String>('sheets.cellCard.link.open'),
                  onTap: () => unawaited(run('sheets.link.open', {'url': url})),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      internal
                          ? '${l.linkCardInternal} · '
                                '${linkTargetLabel(ed.model, url) ?? url}'
                          : url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        color: tokens.linkText,
                        decoration: TextDecoration.underline,
                        decorationColor: tokens.linkText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _CardAction(
              keyName: 'sheets.cellCard.link.copy',
              icon: LucideIcons.copy,
              label: l.linkCardCopy,
              onPressed: () => unawaited(run('sheets.link.copy', {'url': url})),
            ),
            if (ed.canEdit) ...[
              _CardAction(
                keyName: 'sheets.cellCard.link.edit',
                icon: LucideIcons.pencil,
                label: l.linkCardEdit,
                onPressed: () => unawaited(run('sheets.insert.link')),
              ),
              _CardAction(
                keyName: 'sheets.cellCard.link.remove',
                icon: LucideIcons.unlink,
                label: l.linkCardRemove,
                onPressed: () => unawaited(
                  run('sheets.link.remove', {
                    'ranges': [cellA1],
                  }),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ShadTooltip(
    builder: (_) => Text(label),
    child: ShadIconButton.ghost(
      key: ValueKey<String>(keyName),
      width: 28,
      height: 28,
      iconSize: 15,
      semanticLabel: label,
      icon: Icon(icon),
      onPressed: onPressed,
    ),
  );
}
