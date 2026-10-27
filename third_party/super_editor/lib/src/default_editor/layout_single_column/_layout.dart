import 'dart:math';

import 'package:flutter/foundation.dart';
// WONKY PATCH SE-15
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/src/core/document.dart';
import 'package:super_editor/src/core/document_layout.dart';
import 'package:super_editor/src/core/document_selection.dart';
import 'package:super_editor/src/infrastructure/_logging.dart';

import 'package:super_editor/src/default_editor/layout_single_column/_presenter.dart';
// WONKY PATCH SE-15
import 'package:super_editor/src/default_editor/layout_single_column/_cell_layout.dart';

/// Displays a document in a single-column layout.
///
/// [SingleColumnDocumentLayout] displays a series of visual "components".
/// The components are positioned vertically in a column with some space
/// in between.
///
/// The given [presenter] produces component view models, and each of those
/// component view models are turned into visual components by the given
/// [componentBuilders].
///
/// [SingleColumnDocumentLayout]'s `State` object implements [DocumentLayout],
/// which establishes a contract for querying many document layout
/// properties. To use the [DocumentLayout] API, assign a `GlobalKey`
/// to a [SingleColumnDocumentLayout], obtain its `State` object, and then
/// cast that `State` object to a [DocumentLayout].
class SingleColumnDocumentLayout extends StatefulWidget {
  const SingleColumnDocumentLayout({
    Key? key,
    required this.presenter,
    required this.componentBuilders,
    this.onBuildScheduled,
    this.wrapWithSliverAdapter = true,
    this.showDebugPaint = false,
    // WONKY PATCH SE-15
    this.cellLayout,
  }) : super(key: key);

  /// Presenter that provides a view model for a complete single-column
  /// document layout.
  final SingleColumnLayoutPresenter presenter;

  /// Builders for every type of component that this layout displays.
  ///
  /// Every type of [SingleColumnLayoutComponentViewModel] that might
  /// appear in the displayed `document` should have a
  /// [SingleColumnDocumentComponentBuilder] that knows how to render
  /// that piece of content.
  final List<ComponentBuilder> componentBuilders;

  /// Callback that's invoked whenever this widget schedules a build with
  /// `setState()`.
  ///
  /// This callback was added to facilitate the ContentLayers widget, because
  /// Flutter makes it impossible to monitor the dirty state of a sub-tree.
  ///
  /// TODO: Get rid of this as soon as Flutter makes it possible to monitor
  ///       dirty subtrees.
  final VoidCallback? onBuildScheduled;

  /// Whether to wrap this layout with a [SliverToBoxAdapter] so that this layout
  /// can be displayed within a `Sliver`.
  final bool wrapWithSliverAdapter;

  /// Adds a debugging UI to the document layout, when true.
  final bool showDebugPaint;

  /// WONKY PATCH SE-15: places components in cell groups. Maximal runs of
  /// consecutive components whose placements share a group id are laid out
  /// side by side by a [DocumentCellGroupView] (wrapped by
  /// [DocumentCellLayout.wrapGroup]) instead of being stacked in the column.
  /// The layout rebuilds when the cell layout notifies.
  final DocumentCellLayout? cellLayout;

  @override
  State createState() => _SingleColumnDocumentLayoutState();
}

class _SingleColumnDocumentLayoutState extends State<SingleColumnDocumentLayout> implements DocumentLayout {
  final Map<String, GlobalKey> _nodeIdsToComponentKeys = {};
  final Map<GlobalKey, String> _componentKeysToNodeIds = {};

  // Keys are cached in top-to-bottom order so that we can visually
  // traverse components without repeatedly querying a `Document`
  // to determine component ordering.
  final List<GlobalKey> _topToBottomComponentKeys = [];

  late SingleColumnLayoutPresenterChangeListener _presenterListener;

  // The key for the renderBox that contains the actual document layout.
  final GlobalKey _boxKey = GlobalKey();
  BuildContext get boxContext => _boxKey.currentContext!;

  // WONKY PATCH SE-15: the cell group runs of the last build (indices into
  // [_topToBottomComponentKeys]) and the run of every grouped component.
  final List<_CellGroupRun> _cellGroupRuns = [];
  final Map<GlobalKey, _CellGroupRun> _componentKeysToCellGroupRuns = {};

  @override
  void initState() {
    super.initState();

    _presenterListener = SingleColumnLayoutPresenterChangeListener(
      onPresenterMarkedDirty: _onPresenterMarkedDirty,
      onViewModelChange: _onViewModelChange,
    );
    widget.presenter.addChangeListener(_presenterListener);
    // WONKY PATCH SE-15
    widget.cellLayout?.addListener(_onCellLayoutChange);

    // Build the view model now, so that any further changes to the
    // presenter send us a dirty notification.
    widget.presenter.updateViewModel();
  }

  @override
  void didUpdateWidget(SingleColumnDocumentLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.presenter != oldWidget.presenter) {
      oldWidget.presenter.removeChangeListener(_presenterListener);
      widget.presenter.addChangeListener(_presenterListener);

      widget.presenter.updateViewModel();
    }

    // WONKY PATCH SE-15
    if (widget.cellLayout != oldWidget.cellLayout) {
      oldWidget.cellLayout?.removeListener(_onCellLayoutChange);
      widget.cellLayout?.addListener(_onCellLayoutChange);
    }
  }

  @override
  void dispose() {
    widget.presenter.removeChangeListener(_presenterListener);
    // WONKY PATCH SE-15
    widget.cellLayout?.removeListener(_onCellLayoutChange);
    super.dispose();
  }

  /// WONKY PATCH SE-15: placements changed, regroup the components.
  void _onCellLayoutChange() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // Notified during a build or layout: rebuild after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {
      // Re-flow the whole layout.
    });
  }

  Future<void> _onPresenterMarkedDirty() async {
    editorLayoutLog.fine("Layout presenter is dirty. Instructing it to update the view model.");
    widget.presenter.updateViewModel();
  }

  void _onViewModelChange({
    required List<String> addedComponents,
    required List<String> movedComponents,
    required List<String> changedComponents,
    required List<String> removedComponents,
  }) {
    if (addedComponents.isNotEmpty || movedComponents.isNotEmpty || removedComponents.isNotEmpty) {
      setState(() {
        // Re-flow the whole layout.
      });
    }
  }

  @override
  DocumentPosition? getDocumentPositionAtOffset(Offset documentOffset) {
    editorLayoutLog.info('Getting document position at exact offset: $documentOffset');

    final componentKey = _findComponentAtOffset(documentOffset);
    if (componentKey == null || componentKey.currentContext == null) {
      return null;
    }

    return _getDocumentPositionInComponentNearOffset(componentKey, documentOffset);
  }

  @override
  DocumentPosition? getDocumentPositionNearestToOffset(Offset rawDocumentOffset) {
    // Constrain the incoming offset to sit within the width
    // of this document layout.
    final docBox = boxContext.findRenderObject() as RenderBox;
    final documentOffset = Offset(
      // Notice the +1/-1. Experimentally, I determined that if we confine
      // to the exact width, that x-value is considered outside the
      // component RenderBox's. However, 1px less than that is
      // considered to be within the component RenderBox's.
      rawDocumentOffset.dx.clamp(1.0, max(docBox.size.width - 1.0, 1.0)),
      rawDocumentOffset.dy,
    );
    editorLayoutLog.info('Getting document position near offset: $documentOffset');

    if (_isAboveStartOfContent(documentOffset)) {
      // The given offset is above the start of the content.
      // Return the position at the start of the first node.
      final firstPosition = _findFirstPosition();
      if (firstPosition != null) {
        return firstPosition;
      }
    }

    if (_isBeyondDocumentEnd(documentOffset)) {
      // The given offset is beyond the end of the content.
      // Return the position at the end of the last node.
      final lastPosition = _findLastPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
    }

    final componentKey = _findComponentClosestToOffset(documentOffset);
    if (componentKey == null || componentKey.currentContext == null) {
      return null;
    }

    return _getDocumentPositionInComponentNearOffset(componentKey, documentOffset);
  }

  DocumentPosition? _getDocumentPositionInComponentNearOffset(GlobalKey componentKey, Offset documentOffset) {
    final component = componentKey.currentState as DocumentComponent;
    final componentBox = componentKey.currentContext!.findRenderObject() as RenderBox;
    editorLayoutLog.info(' - found node at position: $component');
    final componentOffset = _componentOffset(componentBox, documentOffset);
    final componentPosition = component.getPositionAtOffset(componentOffset);

    if (componentPosition == null) {
      return null;
    }

    final selectionAtOffset = DocumentPosition(
      nodeId: _componentKeysToNodeIds[componentKey]!,
      nodePosition: componentPosition,
    );
    editorLayoutLog.info(' - selection at offset: $selectionAtOffset');
    return selectionAtOffset;
  }

  /// Returns whether or not [documentOffset] is above the start of the document's content.
  bool _isAboveStartOfContent(Offset documentOffset) {
    if (_topToBottomComponentKeys.isEmpty) {
      // There is no component in the document.
      return true;
    }

    final componentKey = _topToBottomComponentKeys.first;
    // WONKY PATCH SE-15: a group starts at its box's top.
    final groupRect = _cellGroupRectOf(componentKey);
    if (groupRect != null) {
      return documentOffset.dy < groupRect.top;
    }
    final componentBox = componentKey.currentContext!.findRenderObject() as RenderBox;
    final offsetAtComponent = _componentOffset(componentBox, documentOffset);

    return offsetAtComponent.dy < 0.0;
  }

  /// Returns whether or not [documentOffset] is beyond the end of the document.
  bool _isBeyondDocumentEnd(Offset documentOffset) {
    if (_topToBottomComponentKeys.isEmpty) {
      // There is no component in the document.
      return true;
    }

    final componentKey = _topToBottomComponentKeys.last;
    // WONKY PATCH SE-15: a group ends at its box's bottom (its last
    // component may be shorter than another cell of the last row).
    final groupRect = _cellGroupRectOf(componentKey);
    if (groupRect != null) {
      return documentOffset.dy > groupRect.bottom;
    }
    final componentBox = componentKey.currentContext!.findRenderObject() as RenderBox;
    final offsetAtComponent = _componentOffset(componentBox, documentOffset);

    return offsetAtComponent.dy > componentBox.size.height;
  }

  @override
  Rect? getEdgeForPosition(DocumentPosition position) {
    final component = getComponentByNodeId(position.nodeId);
    if (component == null) {
      editorLayoutLog.info('Could not find any component for node position: $position');
      return null;
    }

    final componentEdge = component.getEdgeForPosition(position.nodePosition);

    final componentBox = component.context.findRenderObject() as RenderBox;
    final docOffset = componentBox.localToGlobal(Offset.zero, ancestor: boxContext.findRenderObject());

    return componentEdge.translate(docOffset.dx, docOffset.dy);
  }

  @override
  Rect? getRectForPosition(DocumentPosition position) {
    final component = getComponentByNodeId(position.nodeId);
    if (component == null) {
      editorLayoutLog.info('Could not find any component for node position: $position');
      return null;
    }

    final componentRect = component.getRectForPosition(position.nodePosition);

    final componentBox = component.context.findRenderObject() as RenderBox;
    final docOffset = componentBox.localToGlobal(Offset.zero, ancestor: boxContext.findRenderObject());

    return componentRect.translate(docOffset.dx, docOffset.dy);
  }

  @override
  CaretGeometry getCaretForPosition(DocumentPosition position) {
    final component = getComponentByNodeId(position.nodeId);
    if (component == null) {
      throw Exception('Could not find any component for node position: $position');
    }

    final componentCaret = component.getCaretForPosition(position.nodePosition);

    final componentBox = component.context.findRenderObject() as RenderBox;
    final componentOffsetInDocument = componentBox.localToGlobal(Offset.zero, ancestor: boxContext.findRenderObject());

    return componentCaret.translate(componentOffsetInDocument);
  }

  @override
  Rect? getRectForSelection(DocumentPosition base, DocumentPosition extent) {
    final baseComponent = getComponentByNodeId(base.nodeId);
    final extentComponent = getComponentByNodeId(extent.nodeId);
    if (baseComponent == null || extentComponent == null) {
      editorLayoutLog.info(
          'Could not find base and/or extent position to calculate bounding box for selection. Base: $base -> $baseComponent, Extent: $extent -> $extentComponent');
      return null;
    }

    DocumentComponent topComponent;
    final componentBoundingBoxes = <Rect>[];

    // Collect bounding boxes for all selected components.
    final documentLayoutBox = boxContext.findRenderObject() as RenderBox;
    if (base.nodeId == extent.nodeId) {
      // Selection within a single node.
      topComponent = extentComponent;
      final componentOffsetInDocument = (topComponent.context.findRenderObject() as RenderBox)
          .localToGlobal(Offset.zero, ancestor: documentLayoutBox);

      final componentBoundingBox = extentComponent
          .getRectForSelection(
            base.nodePosition,
            extent.nodePosition,
          )
          .translate(
            componentOffsetInDocument.dx,
            componentOffsetInDocument.dy,
          );
      componentBoundingBoxes.add(componentBoundingBox);
    } else {
      // Selection across nodes.
      final selectedNodes = _getNodeIdsBetween(base.nodeId, extent.nodeId);
      topComponent = getComponentByNodeId(selectedNodes.first)!;
      final startPosition = selectedNodes.first == base.nodeId ? base.nodePosition : extent.nodePosition;
      final endPosition = selectedNodes.first == base.nodeId ? extent.nodePosition : base.nodePosition;

      for (int i = 0; i < selectedNodes.length; ++i) {
        final component = getComponentByNodeId(selectedNodes[i])!;
        final componentOffsetInDocument =
            (component.context.findRenderObject() as RenderBox).localToGlobal(Offset.zero, ancestor: documentLayoutBox);

        if (i == 0) {
          // This is the first node. The selection goes from
          // startPosition to the end of the node.
          final firstNodeEndPosition = component.getEndPosition();
          final selectionRectInComponent = component.getRectForSelection(
            startPosition,
            firstNodeEndPosition,
          );
          final componentRectInDocument = selectionRectInComponent.translate(
            componentOffsetInDocument.dx,
            componentOffsetInDocument.dy,
          );
          componentBoundingBoxes.add(componentRectInDocument);
        } else if (i == selectedNodes.length - 1) {
          // This is the last node. The selection goes from
          // the beginning of the node to endPosition.
          final lastNodeStartPosition = component.getBeginningPosition();
          final selectionRectInComponent = component.getRectForSelection(
            lastNodeStartPosition,
            endPosition,
          );
          final componentRectInDocument = selectionRectInComponent.translate(
            componentOffsetInDocument.dx,
            componentOffsetInDocument.dy,
          );
          componentBoundingBoxes.add(componentRectInDocument);
        } else {
          // This node sits between start and end. All content
          // is selected.
          final selectionRectInComponent = component.getRectForSelection(
            component.getBeginningPosition(),
            component.getEndPosition(),
          );
          final componentRectInDocument = selectionRectInComponent.translate(
            componentOffsetInDocument.dx,
            componentOffsetInDocument.dy,
          );
          componentBoundingBoxes.add(componentRectInDocument);
        }
      }
    }

    // Combine all component boxes into one big bounding box.
    Rect boundingBox = componentBoundingBoxes.first;
    for (int i = 1; i < componentBoundingBoxes.length; ++i) {
      boundingBox = boundingBox.expandToInclude(componentBoundingBoxes[i]);
    }

    return boundingBox;
  }

  List<String> _getNodeIdsBetween(String baseNodeId, String extentNodeId) {
    final baseComponentKey = _nodeIdsToComponentKeys[baseNodeId]!;
    final baseComponentIndex = _topToBottomComponentKeys.indexOf(baseComponentKey);
    final extentComponentKey = _nodeIdsToComponentKeys[extentNodeId]!;
    final extentComponentIndex = _topToBottomComponentKeys.indexOf(extentComponentKey);

    final topNodeIndex = baseComponentIndex <= extentComponentIndex ? baseComponentIndex : extentComponentIndex;
    final bottomNodeIndex = topNodeIndex == baseComponentIndex ? extentComponentIndex : baseComponentIndex;
    final componentsInside = _topToBottomComponentKeys.sublist(topNodeIndex, bottomNodeIndex + 1);

    return componentsInside.map((componentKey) => _componentKeysToNodeIds[componentKey]!).toList();
  }

  @override
  DocumentSelection? getDocumentSelectionInRegion(Offset baseOffset, Offset extentOffset) {
    editorLayoutLog.info('getDocumentSelectionInRegion() - from: $baseOffset, to: $extentOffset');
    final region = Rect.fromPoints(baseOffset, extentOffset);

    String? topNodeId;
    dynamic topNodeBasePosition;
    dynamic topNodeExtentPosition;

    String? bottomNodeId;
    dynamic bottomNodeBasePosition;
    dynamic bottomNodeExtentPosition;

    // Find the top and bottom nodes in the selection region. We do this by finding the component
    // at the top of the selection, then we iterate down the document until we find the bottom
    // component in the selection region. We obtain the document nodes from the components.
    final selectionRegionTopOffset = min(baseOffset.dy, extentOffset.dy);
    final componentSearchStartIndex = max(_findComponentIndexAtOffset(selectionRegionTopOffset), 0);
    for (int i = componentSearchStartIndex; i < _topToBottomComponentKeys.length; i++) {
      final componentKey = _topToBottomComponentKeys[i];
      editorLayoutLog.info(' - considering component "$componentKey"');

      // WONKY PATCH SE-15: components of a cell group sit side by side, so a
      // component that doesn't overlap the region doesn't end the search
      // inside a group. A group that doesn't overlap at all is skipped (or
      // ends the search, like any component below the region).
      final cellGroupRun = _componentKeysToCellGroupRuns[componentKey];
      if (cellGroupRun != null && i == cellGroupRun.start) {
        final groupRect = _cellGroupRectOf(componentKey);
        if (groupRect != null && !region.overlaps(groupRect)) {
          if (topNodeId != null) {
            break;
          }
          i = cellGroupRun.end;
          continue;
        }
      }

      if (componentKey.currentState is! DocumentComponent) {
        editorLayoutLog.info(' - found unknown component: ${componentKey.currentState}');
        continue;
      }

      final component = componentKey.currentState as DocumentComponent;

      // Unselectable components should be avoided at base or extent.
      // They should only be selected when the surrounding components are selected.
      if (!component.isVisualSelectionSupported()) {
        editorLayoutLog.fine(' - component does not allow visual selection. Moving on.');
        continue;
      }

      final componentOverlap = _getLocalOverlapWithComponent(region, component);

      if (componentOverlap != null) {
        editorLayoutLog.fine(' - drag intersects: $componentKey}');
        editorLayoutLog.fine(' - intersection: $componentOverlap');
        final componentBaseOffset = _componentOffset(
          componentKey.currentContext!.findRenderObject() as RenderBox,
          baseOffset,
        );
        editorLayoutLog.fine(' - base component offset: $componentBaseOffset');
        final componentExtentOffset = _componentOffset(
          componentKey.currentContext!.findRenderObject() as RenderBox,
          extentOffset,
        );
        editorLayoutLog.fine(' - extent component offset: $componentExtentOffset');

        if (topNodeId == null) {
          // Because we're iterating through components from top to bottom, the
          // first intersecting component that we find must be the top node of
          // the selected area.
          topNodeId = _componentKeysToNodeIds[componentKey];
          topNodeBasePosition = _getNodePositionForComponentOffset(component, componentBaseOffset);
          topNodeExtentPosition = _getNodePositionForComponentOffset(component, componentExtentOffset);
        }
        // We continuously update the bottom node with every additional
        // intersection that we find. This way, when the iteration ends,
        // the last bottom node that we assigned must be the actual bottom
        // node within the selected area.
        bottomNodeId = _componentKeysToNodeIds[componentKey];
        bottomNodeBasePosition = _getNodePositionForComponentOffset(component, componentBaseOffset);
        bottomNodeExtentPosition = _getNodePositionForComponentOffset(component, componentExtentOffset);
      } else if (topNodeId != null && cellGroupRun == null) {
        // We already found an overlapping component and the current component doesn't
        // overlap with the region.
        // Because we're iterating through components from top to bottom,
        // it means that there isn't any other component which will overlap,
        // so we can skip the rest of the list.
        break;
      }
    }

    // WONKY PATCH SE-15: an end of the region inside a cell group resolves to
    // the cell at that point (the nearest one), not to the first overlapping
    // component in document order (which may be an earlier cell of the row).
    final baseCell = _cellGroupComponentNearestTo(baseOffset);
    final extentCell = _cellGroupComponentNearestTo(extentOffset);
    if (baseCell != null || extentCell != null) {
      return _cellAwareSelectionInRegion(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
        baseCell: baseCell,
        extentCell: extentCell,
        topNodeId: topNodeId,
        topNodeBasePosition: topNodeBasePosition,
        topNodeExtentPosition: topNodeExtentPosition,
        bottomNodeId: bottomNodeId,
        bottomNodeBasePosition: bottomNodeBasePosition,
        bottomNodeExtentPosition: bottomNodeExtentPosition,
      );
    }

    if (topNodeId == null || bottomNodeId == null) {
      // No document content exists in the given region.
      editorLayoutLog
          .finer(' - no document content exists in the region. Node at top: $topNodeId. Node at bottom: $bottomNodeId');
      return null;
    }

    if (topNodeId == bottomNodeId) {
      // Region sits within a single component.
      editorLayoutLog.fine(' - the entire selection sits within a single node: $topNodeId');
      return DocumentSelection(
        base: DocumentPosition(
          nodeId: topNodeId,
          nodePosition: topNodeBasePosition,
        ),
        extent: DocumentPosition(
          nodeId: bottomNodeId,
          nodePosition: topNodeExtentPosition,
        ),
      );
    } else {
      // Region covers multiple components.
      editorLayoutLog.fine(' - the selection spans nodes: $topNodeId -> $bottomNodeId');

      // Drag direction determines whether the extent offset is at the
      // top or bottom of the drag rect.
      final isDraggingDown = baseOffset.dy < extentOffset.dy;

      return DocumentSelection(
        base: DocumentPosition(
          nodeId: isDraggingDown ? topNodeId : bottomNodeId,
          nodePosition: isDraggingDown ? topNodeBasePosition : bottomNodeBasePosition,
        ),
        extent: DocumentPosition(
          nodeId: isDraggingDown ? bottomNodeId : topNodeId,
          nodePosition: isDraggingDown ? bottomNodeExtentPosition : topNodeExtentPosition,
        ),
      );
    }
  }

  /// WONKY PATCH SE-15: [getDocumentSelectionInRegion] when its base and/or
  /// extent lies in a cell group: such an end is the position in [baseCell] /
  /// [extentCell] at the offset; another end comes from the region search
  /// (top or bottom node, by drag direction), or else from the nearest
  /// position.
  DocumentSelection? _cellAwareSelectionInRegion({
    required Offset baseOffset,
    required Offset extentOffset,
    required GlobalKey? baseCell,
    required GlobalKey? extentCell,
    required String? topNodeId,
    required dynamic topNodeBasePosition,
    required dynamic topNodeExtentPosition,
    required String? bottomNodeId,
    required dynamic bottomNodeBasePosition,
    required dynamic bottomNodeExtentPosition,
  }) {
    DocumentPosition? positionInCell(GlobalKey cellKey, Offset offset) {
      final component = cellKey.currentState as DocumentComponent;
      final componentBox = cellKey.currentContext!.findRenderObject() as RenderBox;
      final nodePosition = _getNodePositionForComponentOffset(component, _componentOffset(componentBox, offset));
      if (nodePosition == null) {
        return null;
      }
      return DocumentPosition(nodeId: _componentKeysToNodeIds[cellKey]!, nodePosition: nodePosition);
    }

    final isDraggingDown = baseOffset.dy < extentOffset.dy;
    DocumentPosition? regionPosition({required bool isBase}) {
      // The base is the top node when dragging down, the extent the bottom one.
      final useTop = isBase == isDraggingDown;
      final nodeId = useTop ? topNodeId : bottomNodeId;
      final nodePosition = useTop
          ? (isBase ? topNodeBasePosition : topNodeExtentPosition)
          : (isBase ? bottomNodeBasePosition : bottomNodeExtentPosition);
      if (nodeId != null && nodePosition is NodePosition) {
        return DocumentPosition(nodeId: nodeId, nodePosition: nodePosition);
      }
      return getDocumentPositionNearestToOffset(isBase ? baseOffset : extentOffset);
    }

    final base = baseCell != null ? positionInCell(baseCell, baseOffset) : regionPosition(isBase: true);
    final extent = extentCell != null ? positionInCell(extentCell, extentOffset) : regionPosition(isBase: false);
    if (base == null || extent == null) {
      return null;
    }
    return DocumentSelection(base: base, extent: extent);
  }

  /// Returns the overlapping `Rect` between the given `region` and the given
  /// `component`'s bounding box.
  ///
  /// Returns `null` if there is no overlap.
  Rect? _getLocalOverlapWithComponent(Rect region, DocumentComponent component) {
    final componentBox = component.context.findRenderObject() as RenderBox;
    final contentOffset = componentBox.localToGlobal(Offset.zero, ancestor: boxContext.findRenderObject());
    final componentBounds = contentOffset & componentBox.size;
    editorLayoutLog.finest("Component bounds: $componentBounds, versus region of interest: $region");

    if (region.overlaps(componentBounds)) {
      // Report the overlap in our local coordinate space.
      return region.translate(-contentOffset.dx, -contentOffset.dy);
    } else {
      return null;
    }
  }

  /// Returns the [NodePosition] that sits at the given [componentOffset].
  ///
  /// If the [componentOffset] is above the component, then the component's
  /// "beginning" position is returned. If the [componentOffset] is below
  /// the component, then the component's "end" position is returned.
  NodePosition? _getNodePositionForComponentOffset(DocumentComponent component, Offset componentOffset) {
    if (componentOffset.dy < 0) {
      return component.getBeginningPosition();
    }
    if (componentOffset.dy > component.getRectForPosition(component.getEndPosition()).bottom) {
      return component.getEndPosition();
    }

    return component.getPositionAtOffset(componentOffset);
  }

  @override
  MouseCursor? getDesiredCursorAtOffset(Offset documentOffset) {
    final componentKey = _findComponentAtOffset(documentOffset);
    if (componentKey == null ||
        componentKey.currentContext == null ||
        componentKey.currentContext!.findRenderObject() == null) {
      return null;
    }

    final componentBox = componentKey.currentContext!.findRenderObject() as RenderBox;
    final componentOffset = _componentOffset(componentBox, documentOffset);

    final component = componentKey.currentState as DocumentComponent;
    return component.getDesiredCursorAtOffset(componentOffset);
  }

  GlobalKey? _findComponentAtOffset(Offset documentOffset) {
    for (final componentKey in _nodeIdsToComponentKeys.values) {
      if (componentKey.currentState is! DocumentComponent) {
        continue;
      }
      if (componentKey.currentContext == null || componentKey.currentContext!.findRenderObject() == null) {
        continue;
      }

      final textBox = componentKey.currentContext!.findRenderObject() as RenderBox;
      if (_isOffsetInComponent(textBox, documentOffset)) {
        return componentKey;
      }
    }

    // WONKY PATCH SE-15: a point in a cell's slot outside its component (the
    // empty area below a short cell, its padding) belongs to that cell.
    for (final run in _cellGroupRuns) {
      final groupRect = _cellGroupRectOf(_topToBottomComponentKeys[run.start]);
      if (groupRect == null || !groupRect.contains(documentOffset)) {
        continue;
      }
      for (int i = run.start; i <= run.end; i++) {
        final componentKey = _topToBottomComponentKeys[i];
        if (componentKey.currentState is! DocumentComponent) {
          continue;
        }
        final slot = _cellSlotRectOf(componentKey);
        if (slot != null && slot.contains(documentOffset)) {
          return componentKey;
        }
      }
    }
    return null;
  }

  /// WONKY PATCH SE-15: the component of the cell group whose vertical extent
  /// contains [documentOffset] that is nearest to it (2D distance to the
  /// slots, selectable components only), or `null` when [documentOffset] is
  /// not beside a cell group.
  GlobalKey? _cellGroupComponentNearestTo(Offset documentOffset) {
    for (final run in _cellGroupRuns) {
      final groupRect = _cellGroupRectOf(_topToBottomComponentKeys[run.start]);
      if (groupRect == null || documentOffset.dy < groupRect.top || documentOffset.dy > groupRect.bottom) {
        continue;
      }
      GlobalKey? nearest;
      double nearestDistance = double.infinity;
      for (int i = run.start; i <= run.end; i++) {
        final componentKey = _topToBottomComponentKeys[i];
        final state = componentKey.currentState;
        if (state is! DocumentComponent || !state.isVisualSelectionSupported()) {
          continue;
        }
        final slot = _cellSlotRectOf(componentKey);
        if (slot == null) {
          continue;
        }
        final distance = _distanceToRect(slot, documentOffset);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = componentKey;
        }
      }
      return nearest;
    }
    return null;
  }

  /// WONKY PATCH SE-15: the [RenderDocumentCellGroup] that lays out the
  /// component of [componentKey], or `null` when it isn't in a cell group.
  RenderDocumentCellGroup? _cellGroupBoxOf(GlobalKey componentKey) {
    if (!_componentKeysToCellGroupRuns.containsKey(componentKey)) {
      return null;
    }
    final layoutBox = _boxKey.currentContext?.findRenderObject();
    RenderObject? renderObject = componentKey.currentContext?.findRenderObject();
    while (renderObject != null && renderObject != layoutBox) {
      if (renderObject is RenderDocumentCellGroup) {
        return renderObject;
      }
      renderObject = renderObject.parent;
    }
    return null;
  }

  /// WONKY PATCH SE-15: the bounds of the cell group of [componentKey] in
  /// document coordinates, or `null` when it isn't in a cell group.
  Rect? _cellGroupRectOf(GlobalKey componentKey) {
    final groupBox = _cellGroupBoxOf(componentKey);
    if (groupBox == null || !groupBox.hasSize) {
      return null;
    }
    final offset = groupBox.localToGlobal(Offset.zero, ancestor: boxContext.findRenderObject());
    return offset & groupBox.size;
  }

  /// WONKY PATCH SE-15: the slot (column width × row height) of the grouped
  /// component of [componentKey] in document coordinates, or `null` when it
  /// isn't in a cell group.
  Rect? _cellSlotRectOf(GlobalKey componentKey) {
    final groupBox = _cellGroupBoxOf(componentKey);
    final nodeId = _componentKeysToNodeIds[componentKey];
    if (groupBox == null || nodeId == null || !groupBox.hasSize) {
      return null;
    }
    final slot = groupBox.slotRectOf(nodeId);
    if (slot == null) {
      return null;
    }
    final offset = groupBox.localToGlobal(Offset.zero, ancestor: boxContext.findRenderObject());
    return slot.shift(offset);
  }

  /// WONKY PATCH SE-15: the 2D distance between [offset] and [rect] (0 inside).
  double _distanceToRect(Rect rect, Offset offset) {
    final dx = offset.dx < rect.left ? rect.left - offset.dx : (offset.dx > rect.right ? offset.dx - rect.right : 0.0);
    final dy = offset.dy < rect.top ? rect.top - offset.dy : (offset.dy > rect.bottom ? offset.dy - rect.bottom : 0.0);
    return sqrt(dx * dx + dy * dy);
  }

  GlobalKey? _findComponentClosestToOffset(Offset documentOffset) {
    // WONKY PATCH SE-15: beside a cell group (within its vertical extent),
    // the nearest cell of that group.
    final nearestCell = _cellGroupComponentNearestTo(documentOffset);
    if (nearestCell != null) {
      return nearestCell;
    }

    GlobalKey? nearestComponentKey;
    double nearestDistance = double.infinity;
    for (final componentKey in _nodeIdsToComponentKeys.values) {
      if (componentKey.currentState is! DocumentComponent) {
        continue;
      }
      if (componentKey.currentContext == null || componentKey.currentContext!.findRenderObject() == null) {
        continue;
      }

      final componentBox = componentKey.currentContext!.findRenderObject() as RenderBox;
      if (_isOffsetInComponent(componentBox, documentOffset)) {
        return componentKey;
      }

      // WONKY PATCH SE-15: a component in a cell group shares its rows with
      // others, so its distance is the 2D distance to its slot (a point in
      // the slot is in the cell). An ordinary component spans the layout's
      // width, so its distance stays vertical.
      final slot = _cellSlotRectOf(componentKey);
      if (slot != null) {
        final distance = _distanceToRect(slot, documentOffset);
        if (distance == 0) {
          return componentKey;
        }
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestComponentKey = componentKey;
        }
        continue;
      }

      final distance = _getDistanceToComponent(componentBox, documentOffset);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestComponentKey = componentKey;
      }
    }
    return nearestComponentKey;
  }

  /// Returns the [DocumentPosition] at the beginning of the first node or `null` if the document is empty.
  DocumentPosition? _findFirstPosition() {
    if (_topToBottomComponentKeys.isEmpty) {
      return null;
    }

    final componentKey = _topToBottomComponentKeys.first;
    final component = componentKey.currentState as DocumentComponent;

    return DocumentPosition(
      nodeId: _componentKeysToNodeIds[componentKey]!,
      nodePosition: component.getBeginningPosition(),
    );
  }

  /// Returns the [DocumentPosition] at the end of the last node or `null` if the document is empty.
  DocumentPosition? _findLastPosition() {
    if (_topToBottomComponentKeys.isEmpty) {
      return null;
    }

    final componentKey = _topToBottomComponentKeys.last;
    final component = componentKey.currentState as DocumentComponent;

    return DocumentPosition(
      nodeId: _componentKeysToNodeIds[componentKey]!,
      nodePosition: component.getEndPosition(),
    );
  }

  bool _isOffsetInComponent(RenderBox componentBox, Offset documentOffset) {
    final containerBox = boxContext.findRenderObject() as RenderBox;
    final contentOffset = componentBox.localToGlobal(Offset.zero, ancestor: containerBox);
    final contentRect = contentOffset & componentBox.size;

    return contentRect.contains(documentOffset);
  }

  /// Returns the vertical distance between the given [documentOffset] and the
  /// bounds of the given [componentBox].
  ///
  /// WONKY PATCH SE-15: components in cell groups use the 2D distance to their
  /// slot instead, see [_findComponentClosestToOffset].
  double _getDistanceToComponent(RenderBox componentBox, Offset documentOffset) {
    final documentLayoutBox = boxContext.findRenderObject() as RenderBox;
    final componentOffset = componentBox.localToGlobal(Offset.zero, ancestor: documentLayoutBox);
    final componentRect = componentOffset & componentBox.size;

    if (documentOffset.dy < componentRect.top) {
      // The given offset is above the component's bounds.
      return componentRect.top - documentOffset.dy;
    } else if (documentOffset.dy > componentRect.bottom) {
      // The given offset is below the component's bounds.
      return documentOffset.dy - componentRect.bottom;
    } else {
      // The given offset sits within the component bounds.
      return 0;
    }
  }

  Offset _componentOffset(RenderBox componentBox, Offset documentOffset) {
    final containerBox = boxContext.findRenderObject() as RenderBox;
    final contentOffset = componentBox.localToGlobal(Offset.zero, ancestor: containerBox);
    final contentRect = contentOffset & componentBox.size;

    return documentOffset - contentRect.topLeft;
  }

  @override
  DocumentComponent? getComponentByNodeId(String nodeId) {
    final key = _nodeIdsToComponentKeys[nodeId];
    if (key == null) {
      editorLayoutLog.info('WARNING: could not find component for node ID: $nodeId');
      return null;
    }
    if (key.currentState is! DocumentComponent) {
      editorLayoutLog.info(
          'WARNING: found component but it\'s not a DocumentComponent: $nodeId, layout key: $key, state: ${key.currentState}, widget: ${key.currentWidget}, context: ${key.currentContext}');
      if (kDebugMode) {
        throw Exception(
            'WARNING: found component but it\'s not a DocumentComponent: $nodeId, layout key: $key, state: ${key.currentState}, widget: ${key.currentWidget}, context: ${key.currentContext}');
      }
      return null;
    }
    return key.currentState as DocumentComponent;
  }

  @override
  Offset getDocumentOffsetFromAncestorOffset(Offset ancestorOffset, [RenderObject? ancestor]) {
    return (boxContext.findRenderObject() as RenderBox).globalToLocal(ancestorOffset, ancestor: ancestor);
  }

  @override
  Offset getAncestorOffsetFromDocumentOffset(Offset documentOffset, [RenderObject? ancestor]) {
    return (boxContext.findRenderObject() as RenderBox).localToGlobal(documentOffset, ancestor: ancestor);
  }

  @override
  Offset getGlobalOffsetFromDocumentOffset(Offset documentOffset) {
    return (boxContext.findRenderObject() as RenderBox).localToGlobal(documentOffset);
  }

  @override
  DocumentPosition? findLastSelectablePosition() {
    NodePosition? nodePosition;
    String? nodeId;

    for (int i = _topToBottomComponentKeys.length - 1; i >= 0; i--) {
      final componentKey = _topToBottomComponentKeys[i];
      final component = componentKey.currentState as DocumentComponent;

      if (component.isVisualSelectionSupported()) {
        nodePosition = component.getEndPosition();
        nodeId = _componentKeysToNodeIds[componentKey];
        break;
      }
    }

    if (nodePosition == null) {
      return null;
    }

    return DocumentPosition(
      nodeId: nodeId!,
      nodePosition: nodePosition,
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    widget.onBuildScheduled?.call();
  }

  @override
  Widget build(BuildContext context) {
    editorLayoutLog.fine("Building document layout");
    Widget result = Padding(
      key: _boxKey,
      padding: widget.presenter.viewModel.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        // WONKY PATCH SE-15: cell groups.
        children: _groupCells(context, _buildDocComponents()),
      ),
    );

    if (widget.wrapWithSliverAdapter) {
      result = SliverToBoxAdapter(
        child: result,
      );
    }

    editorLayoutLog.fine("Done building document");
    return result;
  }

  List<Widget> _buildDocComponents() {
    editorLayoutLog.fine('Building all document layout components');

    final docComponents = <Widget>[];
    final newComponentKeys = <String, GlobalKey>{};
    final newNodeIds = <GlobalKey, String>{};
    _topToBottomComponentKeys.clear();

    final viewModel = widget.presenter.viewModel;
    editorLayoutLog.fine("Rendering layout view model: ${viewModel.hashCode}");
    for (final componentViewModel in viewModel.componentViewModels) {
      final componentKey = _obtainComponentKeyForDocumentNode(
        newComponentKeyMap: newComponentKeys,
        nodeId: componentViewModel.nodeId,
      );
      newNodeIds[componentKey] = componentViewModel.nodeId;
      editorLayoutLog.finer('Node -> Key: ${componentViewModel.nodeId} -> $componentKey');

      _topToBottomComponentKeys.add(componentKey);

      docComponents.add(
        // Rebuilds whenever this particular component view model changes
        // within the overall layout view model.
        _PresenterComponentBuilder(
          presenter: widget.presenter,
          watchNode: componentViewModel.nodeId,
          builder: (context, newComponentViewModel) {
            // Converts the component view model into a widget.
            return _Component(
              componentBuilders: widget.componentBuilders,
              componentKey: componentKey,
              componentViewModel: newComponentViewModel,
            );
          },
        ),
      );
    }

    _nodeIdsToComponentKeys
      ..clear()
      ..addAll(newComponentKeys);

    _componentKeysToNodeIds
      ..clear()
      ..addAll(newNodeIds);

    editorLayoutLog.finer(' - keys -> IDs after building all components:');
    _nodeIdsToComponentKeys.forEach((key, value) {
      editorLayoutLog.finer('   - $key: $value');
    });

    return docComponents;
  }

  /// WONKY PATCH SE-15: puts maximal runs of consecutive components whose
  /// placements share a group id into one [DocumentCellGroupView], wrapped by
  /// [DocumentCellLayout.wrapGroup]. [components] are in
  /// [_topToBottomComponentKeys] order.
  List<Widget> _groupCells(BuildContext context, List<Widget> components) {
    _cellGroupRuns.clear();
    _componentKeysToCellGroupRuns.clear();
    final cellLayout = widget.cellLayout;
    if (cellLayout == null) {
      return components;
    }

    final placements = [
      for (final key in _topToBottomComponentKeys) cellLayout.placementOf(_componentKeysToNodeIds[key]!),
    ];
    final children = <Widget>[];
    final occurrences = <String, int>{};
    int i = 0;
    while (i < components.length) {
      final placement = placements[i];
      if (placement == null) {
        children.add(components[i]);
        i += 1;
        continue;
      }

      int end = i;
      while (end + 1 < components.length && placements[end + 1]?.group == placement.group) {
        end += 1;
      }
      final run = _CellGroupRun(i, end);
      _cellGroupRuns.add(run);
      for (int j = i; j <= end; j++) {
        _componentKeysToCellGroupRuns[_topToBottomComponentKeys[j]] = run;
      }

      final group = DocumentCellGroup(
        id: placement.group,
        kind: placement.kind,
        nodeIds: [for (int j = i; j <= end; j++) _componentKeysToNodeIds[_topToBottomComponentKeys[j]]!],
      );
      final occurrence = occurrences[placement.group] = (occurrences[placement.group] ?? -1) + 1;
      children.add(
        KeyedSubtree(
          key: ValueKey('wonky-cell-group:${placement.group}#$occurrence'),
          child: cellLayout.wrapGroup(
            context,
            group,
            DocumentCellGroupView(
              group: group,
              placements: [for (int j = i; j <= end; j++) placements[j]!],
              cellLayout: cellLayout,
              children: components.sublist(i, end + 1),
            ),
          ),
        ),
      );
      i = end + 1;
    }
    return children;
  }

  /// Obtains a `GlobalKey` that should be attached to the component
  /// that represents the given [nodeId].
  ///
  /// If a key was already created for the given [nodeId], that same
  /// key is returned. Otherwise, a new key is created, stored for
  /// later, and returned.
  GlobalKey _obtainComponentKeyForDocumentNode({
    required Map<String, GlobalKey> newComponentKeyMap,
    required String nodeId,
  }) {
    if (_nodeIdsToComponentKeys.containsKey(nodeId)) {
      newComponentKeyMap[nodeId] = _nodeIdsToComponentKeys[nodeId]!;
    } else {
      newComponentKeyMap[nodeId] = GlobalKey();
    }
    return newComponentKeyMap[nodeId]!;
  }

  /// Finds the component whose vertical bounds contains the offset [dy].
  ///
  /// Returns the index of the component, from top to bottom order.
  int _findComponentIndexAtOffset(double dy) {
    if (_topToBottomComponentKeys.isEmpty) {
      return -1;
    }
    final index = _binarySearchComponentIndexAtOffset(dy, 0, _topToBottomComponentKeys.length - 1);
    // WONKY PATCH SE-15: start at the first component of a cell group (the
    // search treats a group as one block, see [_getComponentBoundsByIndex]).
    if (index >= 0) {
      final run = _componentKeysToCellGroupRuns[_topToBottomComponentKeys[index]];
      if (run != null) {
        return run.start;
      }
    }
    return index;
  }

  /// Performs a binary search starting from [minIndex] to [maxIndex] to find
  /// a component whose bounds contains the offset [dy].
  ///
  /// Returns the index of the component, from top to bottom order.
  int _binarySearchComponentIndexAtOffset(double dy, int minIndex, int maxIndex) {
    if (minIndex > maxIndex) {
      return -1;
    }

    final middleIndex = ((minIndex + maxIndex) / 2).floor();
    final componentBounds = _getComponentBoundsByIndex(middleIndex);

    if (componentBounds.top <= dy && dy <= componentBounds.bottom) {
      // The component in the middle of the search region is the one we're looking for. Return its index.
      return middleIndex;
    }

    if (dy > componentBounds.bottom) {
      if (middleIndex + 1 < _topToBottomComponentKeys.length) {
        // Check the gap between two components.
        final nextComponentBounds = _getComponentBoundsByIndex(middleIndex + 1);
        final gap = nextComponentBounds.top - componentBounds.bottom;
        if (componentBounds.bottom < dy && dy < (componentBounds.bottom + gap / 2)) {
          // The component we're looking for is somewhere in the bottom half of the current search region.
          return middleIndex;
        }
      }
      return _binarySearchComponentIndexAtOffset(dy, middleIndex + 1, maxIndex);
    } else {
      if (middleIndex - 1 >= 0) {
        // Check the gap between two components.
        final previousComponentBounds = _getComponentBoundsByIndex(middleIndex - 1);
        final gap = componentBounds.top - previousComponentBounds.bottom;
        if ((componentBounds.top - gap / 2) < dy && dy < componentBounds.top) {
          // The component we're looking for is somewhere in the top half of the current search region.
          return middleIndex;
        }
      }
      return _binarySearchComponentIndexAtOffset(dy, minIndex, middleIndex - 1);
    }
  }

  /// Gets the component bounds of the component at [componentIndex] from top to bottom order.
  ///
  /// WONKY PATCH SE-15: for a component in a cell group, the bounds of the
  /// whole group, so that the bounds are ordered top to bottom.
  Rect _getComponentBoundsByIndex(int componentIndex) {
    final componentKey = _topToBottomComponentKeys[componentIndex];
    final groupRect = _cellGroupRectOf(componentKey);
    if (groupRect != null) {
      return groupRect;
    }
    final component = componentKey.currentState as DocumentComponent;

    final componentBox = component.context.findRenderObject() as RenderBox;
    final contentOffset = componentBox.localToGlobal(Offset.zero, ancestor: boxContext.findRenderObject());
    return contentOffset & componentBox.size;
  }
}

/// WONKY PATCH SE-15: the components of a cell group, as indices (inclusive)
/// into the layout's top-to-bottom component keys.
class _CellGroupRun {
  const _CellGroupRun(this.start, this.end);

  final int start;
  final int end;
}

class _PresenterComponentBuilder extends StatefulWidget {
  const _PresenterComponentBuilder({
    Key? key,
    required this.presenter,
    required this.watchNode,
    required this.builder,
  }) : super(key: key);

  final SingleColumnLayoutPresenter presenter;
  final String watchNode;
  final Widget Function(BuildContext, SingleColumnLayoutComponentViewModel) builder;

  @override
  _PresenterComponentBuilderState createState() => _PresenterComponentBuilderState();
}

class _PresenterComponentBuilderState extends State<_PresenterComponentBuilder> {
  late SingleColumnLayoutPresenterChangeListener _presenterListener;

  @override
  void initState() {
    super.initState();

    _presenterListener = SingleColumnLayoutPresenterChangeListener(
      onViewModelChange: _onViewModelChange,
    );
    widget.presenter.addChangeListener(_presenterListener);
  }

  @override
  void didUpdateWidget(_PresenterComponentBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.presenter != oldWidget.presenter) {
      oldWidget.presenter.removeChangeListener(_presenterListener);
      widget.presenter.addChangeListener(_presenterListener);
    }
  }

  @override
  void dispose() {
    widget.presenter.removeChangeListener(_presenterListener);
    super.dispose();
  }

  void _onViewModelChange({
    required List<String> addedComponents,
    required List<String> movedComponents,
    required List<String> changedComponents,
    required List<String> removedComponents,
  }) {
    if (changedComponents.contains(widget.watchNode)) {
      setState(() {
        // Re-build.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    editorLayoutLog.finest("Building component: ${widget.watchNode}");

    final viewModel = widget
        .presenter //
        .viewModel //
        .getComponentViewModelByNodeId(widget.watchNode)!;

    return widget.builder(context, viewModel);
  }
}

/// Builds a component widget for the given [componentViewModel] and
/// binds it to the given [componentKey].
///
/// The specific widget that's build is determined by the given
/// [componentBuilders]. The component widget is rebuilt whenever the
/// given [presenter] reports that the
class _Component extends StatelessWidget {
  const _Component({
    Key? key,
    required this.componentBuilders,
    required this.componentViewModel,
    required this.componentKey,
    // TODO(srawlins): `unused_element`, when reporting a parameter, is being
    // renamed to `unused_element_parameter`. For now, ignore each; when the SDK
    // constraint is >= 3.6.0, just ignore `unused_element_parameter`.
    // ignore: unused_element, unused_element_parameter
    this.showDebugPaint = false,
  }) : super(key: key);

  /// Builders for every type of component that this layout displays.
  ///
  /// Every type of `DocumentNode` that might appear in the displayed
  /// `document` should have a `ComponentBuilder` that knows how to
  /// render that piece of content.
  final List<ComponentBuilder> componentBuilders;

  /// Global key that will be attached to the root of the component
  /// widget sub-tree.
  final GlobalKey componentKey;

  /// The visual configuration for the component that needs to be built.
  final SingleColumnLayoutComponentViewModel componentViewModel;

  /// Whether to add debug paint to the component.
  final bool showDebugPaint;

  @override
  Widget build(BuildContext context) {
    final componentContext = SingleColumnDocumentComponentContext(
      context: context,
      componentKey: componentKey,
    );
    for (final componentBuilder in componentBuilders) {
      var component = componentBuilder.createComponent(componentContext, componentViewModel);
      if (component != null) {
        // TODO: we might need a SizeChangedNotifier here for the case where two components
        //       change size exactly inversely
        component = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: componentViewModel.maxWidth ?? double.infinity),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: componentViewModel.padding,
              child: component,
            ),
          ),
        );

        return showDebugPaint ? _wrapWithDebugWidget(component) : component;
      }
    }
    return const SizedBox();
  }

  Widget _wrapWithDebugWidget(Widget component) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF0000), width: 1),
      ),
      child: component,
    );
  }
}
