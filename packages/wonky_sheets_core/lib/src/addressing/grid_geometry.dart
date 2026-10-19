import 'column_letters.dart';

/// Row or column axis of a sheet. (Named `GridDimension` to avoid clashing with the
/// `Dimension` enum of the Sheets tables.)
enum GridDimension { rows, columns }

/// A cell position in current (zero-based) indices.
final class CellPos implements Comparable<CellPos> {
  final int row;
  final int col;
  const CellPos(this.row, this.col);

  CellPos shift(int dRow, int dCol) => CellPos(row + dRow, col + dCol);

  /// `B3` style address (no sheet, relative).
  String get a1 => '${ColumnLetters.fromIndex(col)}${row + 1}';

  @override
  int compareTo(CellPos other) =>
      row != other.row ? row - other.row : col - other.col;

  @override
  bool operator ==(Object other) =>
      other is CellPos && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => a1;
}

/// An inclusive rectangle of current (zero-based) indices.
final class GridRect {
  final int top;
  final int left;
  final int bottom;
  final int right;

  const GridRect(this.top, this.left, this.bottom, this.right);

  /// Normalizes so that top ≤ bottom and left ≤ right.
  factory GridRect.normalized(int r1, int c1, int r2, int c2) => GridRect(
    r1 < r2 ? r1 : r2,
    c1 < c2 ? c1 : c2,
    r1 < r2 ? r2 : r1,
    c1 < c2 ? c2 : c1,
  );

  factory GridRect.cell(int row, int col) => GridRect(row, col, row, col);

  int get rowCount => bottom - top + 1;
  int get colCount => right - left + 1;
  int get cellCount => rowCount * colCount;
  bool get isSingleCell => top == bottom && left == right;
  CellPos get topLeft => CellPos(top, left);

  bool contains(int row, int col) =>
      row >= top && row <= bottom && col >= left && col <= right;

  bool containsRect(GridRect o) =>
      o.top >= top && o.bottom <= bottom && o.left >= left && o.right <= right;

  bool intersects(GridRect o) =>
      o.top <= bottom && o.bottom >= top && o.left <= right && o.right >= left;

  GridRect? intersection(GridRect o) {
    if (!intersects(o)) return null;
    return GridRect(
      top > o.top ? top : o.top,
      left > o.left ? left : o.left,
      bottom < o.bottom ? bottom : o.bottom,
      right < o.right ? right : o.right,
    );
  }

  GridRect shift(int dRow, int dCol) =>
      GridRect(top + dRow, left + dCol, bottom + dRow, right + dCol);

  /// `A1:B2` (or `A1` for single cells), relative, no sheet.
  String get a1 {
    final start = CellPos(top, left).a1;
    return isSingleCell ? start : '$start:${CellPos(bottom, right).a1}';
  }

  @override
  bool operator ==(Object other) =>
      other is GridRect &&
      other.top == top &&
      other.left == left &&
      other.bottom == bottom &&
      other.right == right;

  @override
  int get hashCode => Object.hash(top, left, bottom, right);

  @override
  String toString() => 'GridRect($a1)';
}
