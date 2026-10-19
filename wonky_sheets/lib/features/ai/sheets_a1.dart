import 'package:wonky_sheets_core/formula.dart'
    show CellPos, ColumnLetters, GridRect, SheetNames;

import '../grid/selection/grid_selection.dart';
import '../sheet_editor/sheet_editor_controller.dart';

/// A1 text of [rect] (`B4`, `A1:C9`, `2:5`, `B:D`).
String rectA1(
  GridRect rect, {
  bool wholeRows = false,
  bool wholeColumns = false,
}) {
  if (wholeRows && wholeColumns) return rect.a1;
  if (wholeRows) return '${rect.top + 1}:${rect.bottom + 1}';
  if (wholeColumns) {
    return '${ColumnLetters.fromIndex(rect.left)}:'
        '${ColumnLetters.fromIndex(rect.right)}';
  }
  return rect.isSingleCell ? CellPos(rect.top, rect.left).a1 : rect.a1;
}

/// `Sheet1!B4`, `'Q3 Plan'!A1:C9`.
String qualifiedA1(String sheetName, String a1) =>
    '${SheetNames.quoteIfNeeded(sheetName)}!$a1';

/// A1 helpers of an editor.
extension SheetsEditorA1 on SheetEditorController {
  /// The name of sheet [sheetId] (the id when unknown).
  String sheetName(String sheetId) => model.sheet(sheetId)?.name ?? sheetId;

  /// A selection range as qualified A1.
  String selectionRangeA1(ResolvedSelectionRange r, {String? sheetId}) {
    final name = sheetName(sheetId ?? activeSheetId);
    if (r.kind == SelectionKind.all) {
      return qualifiedA1(name, r.rect.a1);
    }
    return qualifiedA1(
      name,
      rectA1(
        r.rect,
        wholeRows: r.kind == SelectionKind.rows,
        wholeColumns: r.kind == SelectionKind.columns,
      ),
    );
  }

  /// Every selected range as qualified A1.
  List<String> get selectionA1 {
    final r = selection.resolved;
    return [for (final x in r.ranges) selectionRangeA1(x, sheetId: r.sheetId)];
  }

  /// The active cell as qualified A1.
  String get activeCellA1 {
    final r = selection.resolved;
    return qualifiedA1(
      sheetName(r.sheetId),
      CellPos(r.activeRow, r.activeCol).a1,
    );
  }

  /// The range visible in the main pane (null before the first paint).
  String? get visibleRangeA1 {
    final g = geometry;
    if (g == null || g.main.isEmpty) return null;
    final (r0, r1) = g.visibleRows;
    final (c0, c1) = g.visibleCols;
    final top = g.frozenRows > 0 ? 0 : r0;
    final left = g.frozenCols > 0 ? 0 : c0;
    return qualifiedA1(
      sheetName(activeSheetId),
      GridRect(top, left, r1, c1).a1,
    );
  }
}
