import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../../l10n/sheets_l10n.dart';
import '../pivot_controller.dart';

/// The floating ✎ *Edit* button of the selected pivot table (03 §14.9):
/// next to the top-right corner of the output, shown while the active cell
/// is inside it; opens the pivot editor panel.
class PivotEditButton extends StatelessWidget {
  const PivotEditButton({super.key, required this.controller});

  final PivotController controller;

  static const double _height = 28;

  @override
  Widget build(BuildContext context) {
    final ed = controller.editor;
    return ListenableBuilder(
      listenable: Listenable.merge([ed.overlaySignal, ed.scroll, controller]),
      builder: (context, _) {
        final o = controller.activeOutput;
        final g = ed.geometry;
        if (o == null || g == null || ed.editor.isEditing) {
          return const SizedBox.shrink();
        }
        final l = sheetsL10n(context);
        final cells = g.cellsRect;
        final r = g.rangeRect(o.rect);
        if (r.right < cells.left ||
            r.left > cells.right ||
            r.bottom < cells.top ||
            r.top > cells.bottom) {
          return const SizedBox.shrink();
        }
        const width = 72.0;
        // An empty pivot is one cell whose placeholder text overflows to the
        // right: the button goes under it instead of over the text.
        final below = o.rect.rowCount == 1 && o.rect.colCount == 1;
        var left = below ? r.left : r.right + 4;
        if (left + width > cells.right - 12) left = r.right - width - 4;
        left = left.clamp(cells.left + 4, cells.right - width - 12);
        final top = (below ? r.bottom + 4 : r.top).clamp(
          cells.top + 4,
          cells.bottom - _height - 4,
        );
        return Positioned(
          left: left,
          top: top.toDouble(),
          child: ShadTooltip(
            builder: (_) => Text(l.cmdPivotOpenEditor),
            child: ShadButton.secondary(
              key: const ValueKey<String>('sheets.pivot.editButton'),
              size: ShadButtonSize.sm,
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              leading: const Icon(LucideIcons.pencil, size: 14),
              onPressed: () => ed.invokeCommand('sheets.pivot.openEditor', {
                'pivotId': o.id,
              }),
              child: Text(l.pivotEditButton),
            ),
          ),
        );
      },
    );
  }
}
