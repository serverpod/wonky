// WONKY PATCH SE-15: cell groups. Consecutive components that a
// [DocumentCellLayout] places in the same group are laid out side by side
// (table rows or a flowing grid) instead of being stacked in the column.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// How a cell group arranges its components.
enum DocumentCellGroupKind {
  /// Every placement names its row and column (a table).
  rows,

  /// Items fill rows left to right in index order (a grid).
  flow,
}

/// Where a node's component goes inside a cell group.
///
/// The group-wide values ([minColumnWidth], [gap] and, for flows,
/// [maxColumns]) are taken from the group's first placement.
@immutable
class DocumentCellPlacement {
  /// A table cell: [row] and [column] inside group [group].
  const DocumentCellPlacement.rows({
    required this.group,
    required this.row,
    required this.column,
    this.minColumnWidth = 64,
    this.gap = 0,
    this.spaceBefore = 0,
  })  : kind = DocumentCellGroupKind.rows,
        index = 0,
        maxColumns = 0;

  /// A grid item: [index] in a flow of at most [maxColumns] columns; the
  /// column count drops while columns would be narrower than [minColumnWidth].
  const DocumentCellPlacement.flow({
    required this.group,
    required this.index,
    required this.maxColumns,
    this.minColumnWidth = 160,
    this.gap = 0,
    this.spaceBefore = 0,
  })  : kind = DocumentCellGroupKind.flow,
        row = 0,
        column = 0;

  /// The group id; consecutive components with the same id form one group.
  final String group;

  final DocumentCellGroupKind kind;

  /// [DocumentCellGroupKind.rows]: the cell's row (0 for flows).
  final int row;

  /// [DocumentCellGroupKind.rows]: the cell's column (0 for flows).
  final int column;

  /// [DocumentCellGroupKind.flow]: the item's index (0 for rows).
  final int index;

  /// [DocumentCellGroupKind.flow]: the maximum column count (0 for rows).
  final int maxColumns;

  /// Columns are never narrower than this (rows: they overflow; flows: the
  /// column count drops).
  final double minColumnWidth;

  /// Space between columns and between rows.
  final double gap;

  /// Vertical space above this placement's row (the maximum of the row's
  /// placements is used), e.g. to push a row to the next page.
  final double spaceBefore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentCellPlacement &&
          other.group == group &&
          other.kind == kind &&
          other.row == row &&
          other.column == column &&
          other.index == index &&
          other.maxColumns == maxColumns &&
          other.minColumnWidth == minColumnWidth &&
          other.gap == gap &&
          other.spaceBefore == spaceBefore;

  @override
  int get hashCode => Object.hash(group, kind, row, column, index, maxColumns, minColumnWidth, gap, spaceBefore);

  @override
  String toString() => kind == DocumentCellGroupKind.rows
      ? 'DocumentCellPlacement.rows($group, row: $row, column: $column)'
      : 'DocumentCellPlacement.flow($group, index: $index, maxColumns: $maxColumns)';
}

/// One group as laid out: its id, kind and its nodes in document order.
@immutable
class DocumentCellGroup {
  const DocumentCellGroup({
    required this.id,
    required this.kind,
    required this.nodeIds,
  });

  final String id;
  final DocumentCellGroupKind kind;
  final List<String> nodeIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentCellGroup && other.id == id && other.kind == kind && listEquals(other.nodeIds, nodeIds);

  @override
  int get hashCode => Object.hash(id, kind, Object.hashAll(nodeIds));

  @override
  String toString() => 'DocumentCellGroup($id, $kind, $nodeIds)';
}

/// The geometry handed to [DocumentCellLayout.paintGroup], in the group's
/// local coordinates.
@immutable
class DocumentCellGroupGeometry {
  DocumentCellGroupGeometry({
    required this.group,
    required this.size,
    required this.rowCount,
    required this.columnCount,
    required this.columnEdges,
    required this.rowEdges,
    required this.slotRects,
    List<double>? rowBottoms,
  }) : rowBottoms = rowBottoms ?? [for (int i = 1; i < rowEdges.length; i++) rowEdges[i]];

  final DocumentCellGroup group;

  /// The size of the group.
  final Size size;

  final int rowCount;
  final int columnCount;

  /// `columnCount + 1` x positions: the left edge of every column, then the
  /// right edge of the last column (with a gap, a column ends `gap` before the
  /// next one starts).
  final List<double> columnEdges;

  /// `rowCount + 1` y positions: the top of every row, then the bottom of the
  /// last row. The `spaceBefore` above a row is not part of the row (it lies
  /// between the previous row's bottom and the row's top).
  final List<double> rowEdges;

  /// The bottom of every row (`rowCount` y positions). Differs from the next
  /// row's top when there is a gap or a `spaceBefore`.
  final List<double> rowBottoms;

  /// Node id → its full slot (column width × row height), not the child's
  /// natural size.
  final Map<String, Rect> slotRects;
}

/// Supplied by the app; tells the layout which components form cell groups.
///
/// Notify listeners when a placement (or anything [wrapGroup] or
/// [paintGroup] depends on) changes: the document layout rebuilds its groups
/// and the groups repaint.
abstract class DocumentCellLayout implements Listenable {
  /// The placement of the component of [nodeId], or `null` when it is an
  /// ordinary component of the column.
  DocumentCellPlacement? placementOf(String nodeId);

  /// Wraps a group's [child] (a [DocumentCellGroupView]), e.g. in a frame.
  /// Return [child] for no decoration.
  Widget wrapGroup(BuildContext context, DocumentCellGroup group, Widget child);

  /// Paints behind the group's cells, e.g. table borders.
  void paintGroup(Canvas canvas, Offset offset, DocumentCellGroupGeometry geometry);
}

/// Lays out the components of one cell group: [children] and [placements]
/// correspond one to one, in document order ([DocumentCellGroup.nodeIds]).
class DocumentCellGroupView extends MultiChildRenderObjectWidget {
  DocumentCellGroupView({
    super.key,
    required this.group,
    required this.placements,
    required this.cellLayout,
    required super.children,
  })  : assert(placements.length == children.length),
        assert(group.nodeIds.length == children.length);

  final DocumentCellGroup group;
  final List<DocumentCellPlacement> placements;
  final DocumentCellLayout cellLayout;

  @override
  RenderDocumentCellGroup createRenderObject(BuildContext context) {
    return RenderDocumentCellGroup(group: group, placements: placements, cellLayout: cellLayout);
  }

  @override
  void updateRenderObject(BuildContext context, RenderDocumentCellGroup renderObject) {
    renderObject
      ..group = group
      ..placements = placements
      ..cellLayout = cellLayout;
  }
}

class _CellGroupParentData extends ContainerBoxParentData<RenderBox> {}

/// The render object of [DocumentCellGroupView].
class RenderDocumentCellGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellGroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellGroupParentData> {
  RenderDocumentCellGroup({
    required DocumentCellGroup group,
    required List<DocumentCellPlacement> placements,
    required DocumentCellLayout cellLayout,
  })  : _group = group,
        _placements = placements,
        _cellLayout = cellLayout;

  DocumentCellGroup get group => _group;
  DocumentCellGroup _group;
  set group(DocumentCellGroup value) {
    if (value == _group) return;
    _group = value;
    markNeedsLayout();
  }

  List<DocumentCellPlacement> get placements => _placements;
  List<DocumentCellPlacement> _placements;
  set placements(List<DocumentCellPlacement> value) {
    if (listEquals(value, _placements)) return;
    _placements = value;
    markNeedsLayout();
  }

  DocumentCellLayout get cellLayout => _cellLayout;
  DocumentCellLayout _cellLayout;
  set cellLayout(DocumentCellLayout value) {
    if (identical(value, _cellLayout)) return;
    if (attached) {
      _cellLayout.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _cellLayout = value;
    markNeedsPaint();
  }

  /// The geometry of the last layout, `null` before the first.
  DocumentCellGroupGeometry? get geometry => _geometry;
  DocumentCellGroupGeometry? _geometry;

  /// The slot of [nodeId] in this group's coordinates (after layout).
  Rect? slotRectOf(String nodeId) => _geometry?.slotRects[nodeId];

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _cellLayout.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _cellLayout.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellGroupParentData) {
      child.parentData = _CellGroupParentData();
    }
  }

  List<RenderBox> get _children {
    final children = <RenderBox>[];
    RenderBox? child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }

  DocumentCellPlacement? get _first => _placements.isEmpty ? null : _placements.first;

  double get _gap => max(0.0, _first?.gap ?? 0.0);

  double get _minColumnWidth => max(0.0, _first?.minColumnWidth ?? 0.0);

  /// Assigns every child (by index) a row and a column, and returns the
  /// column count.
  _CellGrid _grid(double width) {
    final count = min(_placements.length, childCount);
    final rows = List<int>.filled(count, 0);
    final columns = List<int>.filled(count, 0);
    if (count == 0) {
      return _CellGrid(rows, columns, 0, 0);
    }
    final gap = _gap;
    final minColumnWidth = _minColumnWidth;
    if (_group.kind == DocumentCellGroupKind.rows) {
      int rowCount = 0;
      int columnCount = 0;
      for (int i = 0; i < count; i++) {
        rows[i] = max(0, _placements[i].row);
        columns[i] = max(0, _placements[i].column);
        rowCount = max(rowCount, rows[i] + 1);
        columnCount = max(columnCount, columns[i] + 1);
      }
      return _CellGrid(rows, columns, rowCount, columnCount);
    }

    // Flow: the column count drops while columns would be too narrow.
    int columnCount = max(1, _first!.maxColumns);
    if (width.isFinite) {
      while (columnCount > 1 && (width - gap * (columnCount - 1)) / columnCount < minColumnWidth) {
        columnCount--;
      }
    }
    final order = List<int>.generate(count, (i) => i)
      ..sort((a, b) {
        final byIndex = _placements[a].index.compareTo(_placements[b].index);
        return byIndex != 0 ? byIndex : a.compareTo(b);
      });
    for (int rank = 0; rank < count; rank++) {
      rows[order[rank]] = rank ~/ columnCount;
      columns[order[rank]] = rank % columnCount;
    }
    return _CellGrid(rows, columns, (count + columnCount - 1) ~/ columnCount, columnCount);
  }

  double _columnWidth(double width, int columnCount) {
    if (columnCount == 0) return 0;
    final minColumnWidth = _minColumnWidth;
    if (!width.isFinite) return minColumnWidth;
    final shared = max(0.0, (width - _gap * (columnCount - 1)) / columnCount);
    // Rows keep columns at their minimum width (and overflow); a flow already
    // dropped columns, and a single column narrower than the minimum takes
    // the available width.
    return _group.kind == DocumentCellGroupKind.rows ? max(minColumnWidth, shared) : shared;
  }

  /// Computes the geometry for [width] with the children's heights from
  /// [childHeight] (layout, dry layout or intrinsics).
  DocumentCellGroupGeometry _computeGeometry(
    double width,
    double Function(RenderBox child, double columnWidth) childHeight, {
    List<Offset>? childOffsets,
  }) {
    final children = _children;
    final grid = _grid(width);
    final gap = _gap;
    final columnWidth = _columnWidth(width, grid.columnCount);

    final rowHeights = List<double>.filled(grid.rowCount, 0);
    final rowSpaceBefore = List<double>.filled(grid.rowCount, 0);
    for (int i = 0; i < grid.rows.length; i++) {
      final row = grid.rows[i];
      rowHeights[row] = max(rowHeights[row], childHeight(children[i], columnWidth));
      rowSpaceBefore[row] = max(rowSpaceBefore[row], max(0.0, _placements[i].spaceBefore));
    }

    final columnEdges = <double>[
      for (int c = 0; c < grid.columnCount; c++) c * (columnWidth + gap),
      if (grid.columnCount > 0) grid.columnCount * columnWidth + (grid.columnCount - 1) * gap else 0,
    ];

    final rowTops = <double>[];
    final rowBottoms = <double>[];
    double y = 0;
    for (int r = 0; r < grid.rowCount; r++) {
      if (r > 0) y += gap;
      y += rowSpaceBefore[r];
      rowTops.add(y);
      y += rowHeights[r];
      rowBottoms.add(y);
    }

    final slotRects = <String, Rect>{};
    for (int i = 0; i < grid.rows.length; i++) {
      final row = grid.rows[i];
      final column = grid.columns[i];
      final slot = Rect.fromLTWH(columnEdges[column], rowTops[row], columnWidth, rowHeights[row]);
      if (i < _group.nodeIds.length) {
        slotRects[_group.nodeIds[i]] = slot;
      }
      childOffsets?.add(slot.topLeft);
    }

    final contentWidth = columnEdges.last;
    return DocumentCellGroupGeometry(
      group: _group,
      size: Size(width.isFinite ? width : contentWidth, y),
      rowCount: grid.rowCount,
      columnCount: grid.columnCount,
      columnEdges: columnEdges,
      rowEdges: [...rowTops, if (rowBottoms.isNotEmpty) rowBottoms.last else 0],
      rowBottoms: rowBottoms,
      slotRects: slotRects,
    );
  }

  double _widthFor(BoxConstraints constraints) {
    if (constraints.hasBoundedWidth) return constraints.maxWidth;
    // Unbounded: as wide as the narrowest columns allow.
    return constraints.constrainWidth(computeMinIntrinsicWidth(double.infinity));
  }

  @override
  void performLayout() {
    final width = _widthFor(constraints);
    final offsets = <Offset>[];
    final geometry = _computeGeometry(
      width,
      (child, columnWidth) {
        child.layout(BoxConstraints.tightFor(width: columnWidth), parentUsesSize: true);
        return child.size.height;
      },
      childOffsets: offsets,
    );
    final children = _children;
    for (int i = 0; i < children.length; i++) {
      final parentData = children[i].parentData as _CellGroupParentData;
      if (i < offsets.length) {
        parentData.offset = offsets[i];
      } else {
        // A child without a placement (never expected): lay it out hidden.
        children[i].layout(const BoxConstraints.tightFor(width: 0, height: 0));
        parentData.offset = Offset.zero;
      }
    }
    _geometry = geometry;
    size = constraints.constrain(geometry.size);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = _widthFor(constraints);
    final geometry = _computeGeometry(
      width,
      (child, columnWidth) => child.getDryLayout(BoxConstraints.tightFor(width: columnWidth)).height,
    );
    return constraints.constrain(geometry.size);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final grid = _grid(double.infinity);
    if (grid.columnCount == 0) return 0;
    final columns = _group.kind == DocumentCellGroupKind.rows ? grid.columnCount : 1;
    return columns * _minColumnWidth + (columns - 1) * _gap;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = _children;
    final grid = _grid(double.infinity);
    if (grid.columnCount == 0) return 0;
    final columnWidths = List<double>.filled(grid.columnCount, _minColumnWidth);
    for (int i = 0; i < grid.columns.length; i++) {
      final column = grid.columns[i];
      columnWidths[column] = max(columnWidths[column], children[i].getMaxIntrinsicWidth(double.infinity));
    }
    // Columns share the width equally, so all are as wide as the widest.
    final widest = columnWidths.reduce(max);
    return grid.columnCount * widest + (grid.columnCount - 1) * _gap;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeGeometry(width, (child, columnWidth) => child.getMinIntrinsicHeight(columnWidth)).size.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeGeometry(width, (child, columnWidth) => child.getMaxIntrinsicHeight(columnWidth)).size.height;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final geometry = _geometry;
    if (geometry != null) {
      _cellLayout.paintGroup(context.canvas, offset, geometry);
    }
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DocumentCellGroup>('group', _group));
  }
}

class _CellGrid {
  _CellGrid(this.rows, this.columns, this.rowCount, this.columnCount);

  /// Row and column of every child, by child index.
  final List<int> rows;
  final List<int> columns;
  final int rowCount;
  final int columnCount;
}
