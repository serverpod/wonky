import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import '../requests/cell_editing_handlers.dart';

/// Tab, Shift+Tab, ↑ and ↓ in table cells and grid items (Write 12 §3.4):
/// Tab walks the cells (selecting the next cell's text) and appends a row
/// or item after the last; ↑/↓ go to the cell above or below in the laid
/// out table or grid, keeping the caret's x, and leave it at its edges.
/// Enter, Backspace and Delete are request handlers
/// ([cellEditingHandlers]).
bool cellKeys(KeyEvent event, WriteEditorController controller) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
  final key = event.logicalKey;
  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isAltPressed ||
      keyboard.isMetaPressed ||
      keyboard.isControlPressed) {
    return false;
  }
  final selection = controller.composer.selection;
  if (selection == null) return false;
  final document = controller.document;
  final node = document.getNodeById(selection.extent.nodeId);
  final group = CellGroupNodes.of(document, node);
  if (group == null || node is! TextNode) return false;
  final shift = keyboard.isShiftPressed;

  if (key == LogicalKeyboardKey.tab) {
    final i = group.nodes.indexOf(node);
    final next = shift ? i - 1 : i + 1;
    if (next < 0) return true;
    if (next >= group.nodes.length) {
      // Read-only: Tab walks the cells but appends nothing.
      if (controller.mode == EditorMode.viewing) return true;
      controller.editor.execute([AppendCellRequest(node.id)]);
      return true;
    }
    final target = group.nodes[next] as TextNode;
    _select(
      controller,
      DocumentSelection(
        base: DocumentPosition(
          nodeId: target.id,
          nodePosition: const TextNodePosition(offset: 0),
        ),
        extent: DocumentPosition(
          nodeId: target.id,
          nodePosition: TextNodePosition(offset: target.text.length),
        ),
      ),
    );
    return true;
  }

  final up = key == LogicalKeyboardKey.arrowUp;
  if (!up && key != LogicalKeyboardKey.arrowDown) return false;
  if (shift) return false;
  final layout = controller.documentLayout;
  final position = selection.extent.nodePosition;
  if (layout == null || position is! TextNodePosition) return false;
  final component = layout.getComponentByNodeId(node.id);
  if (component == null) return false;
  // Within a cell's wrapped lines, the default moves the caret.
  final within = up
      ? component.movePositionUp(position)
      : component.movePositionDown(position);
  if (within != null) return false;
  final caret = layout.getRectForPosition(selection.extent);
  if (caret == null) return false;
  final x = caret.center.dx;

  // The nearest cell whose box is above (below) the caret's cell.
  final here = _boxOf(layout, node.id);
  if (here == null) return false;
  DocumentNode? best;
  Rect? bestBox;
  for (final n in group.nodes) {
    if (n.id == node.id) continue;
    final box = _boxOf(layout, n.id);
    if (box == null) continue;
    final isAbove = box.bottom <= here.top + 0.5;
    final isBelow = box.top >= here.bottom - 0.5;
    if (up ? !isAbove : !isBelow) continue;
    if (bestBox == null) {
      best = n;
      bestBox = box;
      continue;
    }
    final closer = up
        ? box.bottom > bestBox.bottom + 0.5
        : box.top < bestBox.top - 0.5;
    final sameRow = (box.top - bestBox.top).abs() <= 0.5;
    if (closer || (sameRow && _dx(box, x) < _dx(bestBox, x))) {
      best = n;
      bestBox = box;
    }
  }
  // At the table's edge: the block before or after it.
  best ??= up
      ? document.getNodeBeforeById(group.nodes.first.id)
      : document.getNodeAfterById(group.nodes.last.id);
  if (best == null) return true;
  final target = layout.getComponentByNodeId(best.id);
  final targetBox = _boxOf(layout, best.id);
  if (target == null || targetBox == null) return false;
  final local = x - targetBox.left;
  _select(
    controller,
    DocumentSelection.collapsed(
      position: DocumentPosition(
        nodeId: best.id,
        nodePosition: up
            ? target.getEndPositionNearX(local)
            : target.getBeginningPositionNearX(local),
      ),
    ),
  );
  return true;
}

double _dx(Rect box, double x) =>
    x < box.left ? box.left - x : (x > box.right ? x - box.right : 0);

/// The component box of [nodeId] in document coordinates.
Rect? _boxOf(DocumentLayout layout, String nodeId) {
  final component = layout.getComponentByNodeId(nodeId);
  if (component is! State) return null;
  final box = (component as State).context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final topLeft = layout.getDocumentOffsetFromAncestorOffset(Offset.zero, box);
  return topLeft & box.size;
}

void _select(WriteEditorController controller, DocumentSelection selection) {
  controller.editor.execute([
    ChangeSelectionRequest(
      selection,
      SelectionChangeType.placeCaret,
      SelectionReason.userInteraction,
    ),
  ]);
}
