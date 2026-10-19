import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../filters/filter_column_popover.dart';
import '../filters/filter_controller.dart';
import '../find/find_bar.dart';
import '../find/find_replace_dialog.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'data_tools.dart';
import 'split_chip.dart';

/// Floating data-tool UI over the grid (same box as `GridArea`): the find
/// bar, the Find and replace dialog, the filter column popover and the
/// split separator chip. Empty areas let pointer events through.
class DataToolsGridOverlay extends StatelessWidget {
  const DataToolsGridOverlay({super.key, required this.editor});

  final SheetEditorController editor;

  @override
  Widget build(BuildContext context) {
    final tools = DataTools.of(editor);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: tools.find.barOpen,
            builder: (context, open, _) => !open
                ? const SizedBox.shrink()
                : Positioned(
                    top: 6,
                    right: 18,
                    child: FindBar(editor: editor, find: tools.find),
                  ),
          ),
          ValueListenableBuilder<FilterPopoverRequest?>(
            valueListenable: tools.filters.popover,
            builder: (context, req, _) => req == null
                ? const SizedBox.shrink()
                : _FilterPopoverAnchor(
                    key: ValueKey<Object>(req),
                    editor: editor,
                    tools: tools,
                    request: req,
                    areaHeight: constraints.maxHeight,
                  ),
          ),
          ValueListenableBuilder<SplitChipState?>(
            valueListenable: tools.splitChip,
            builder: (context, st, _) => st == null
                ? const SizedBox.shrink()
                : _SplitChipPositioned(editor: editor, state: st),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: tools.find.dialogOpen,
            builder: (context, open, _) => !open
                ? const SizedBox.shrink()
                : FindReplaceDialog(
                    editor: editor,
                    find: tools.find,
                    bounds: constraints.biggest,
                  ),
          ),
        ],
      ),
    );
  }
}

/// An invisible box at the filter button that hosts the popover.
class _FilterPopoverAnchor extends StatefulWidget {
  const _FilterPopoverAnchor({
    super.key,
    required this.editor,
    required this.tools,
    required this.request,
    required this.areaHeight,
  });

  final SheetEditorController editor;
  final DataTools tools;
  final FilterPopoverRequest request;
  final double areaHeight;

  @override
  State<_FilterPopoverAnchor> createState() => _FilterPopoverAnchorState();
}

class _FilterPopoverAnchorState extends State<_FilterPopoverAnchor> {
  final _controller = ShadPopoverController(isOpen: true);
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_controller.isOpen) _close();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    final f = widget.tools.filters;
    f.clearDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (f.popover.value == widget.request) f.popover.value = null;
      widget.editor.gridFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final filter = widget.tools.filters.effective(r.sheetId);
    if (filter == null) return const SizedBox.shrink();
    final below = widget.areaHeight - r.anchor.bottom - 24;
    final maxHeight = math.max(260.0, math.min(520.0, below + 120));
    // Right-aligned to the button like Google Sheets, unless that would push
    // the popover (280 px wide) off the left edge (column A, Mod+Alt+R).
    final fitsLeft = r.anchor.right >= kFilterPopoverWidth + 16;
    return Positioned.fromRect(
      rect: r.anchor,
      child: ShadPopover(
        controller: _controller,
        anchor: fitsLeft
            ? const ShadAnchor(
                childAlignment: Alignment.bottomRight,
                overlayAlignment: Alignment.topRight,
                offset: Offset(0, 4),
              )
            : const ShadAnchor(
                childAlignment: Alignment.bottomLeft,
                overlayAlignment: Alignment.topLeft,
                offset: Offset(0, 4),
              ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        popover: (context) => FilterColumnPopover(
          editor: widget.editor,
          filters: widget.tools.filters,
          filter: filter,
          colId: r.colId,
          maxHeight: maxHeight,
          onClose: () {
            _close();
            _controller.hide();
          },
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SplitChipPositioned extends StatelessWidget {
  const _SplitChipPositioned({required this.editor, required this.state});

  final SheetEditorController editor;
  final SplitChipState state;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([editor.scroll, editor.overlaySignal]),
    builder: (context, _) {
      final g = editor.geometry;
      if (g == null || editor.activeSheetId != state.sheetId) {
        return const SizedBox.shrink();
      }
      final rect = g.rangeRect(state.range);
      final top = math.min(rect.bottom + 6, g.size.height - 44);
      final left = math.max(g.rowHeaderWidth + 4, rect.left);
      return Positioned(
        left: left,
        top: math.max(g.colHeaderHeight + 4, top),
        child: SplitSeparatorChip(
          key: ValueKey<Object>(state),
          editor: editor,
          state: state,
        ),
      );
    },
  );
}
