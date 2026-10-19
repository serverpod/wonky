import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_ui/wonky_ui.dart'
    show RemoteCaret, RemoteSelectionPainter;

import '../controller/write_editor_controller.dart';
import '../model/document_queries.dart';
import '../styles/editor_theme.dart';
import '../view/editor_view_state.dart';
import 'document_geometry.dart';

/// Rectangles painted under the document text.
class _UnderlayData {
  const _UnderlayData({
    required this.findRects,
    required this.activeFindRects,
    required this.pendingCommentRects,
    required this.remoteSelections,
    required this.blockSelectionRects,
  });

  final List<Rect> findRects;
  final List<Rect> activeFindRects;
  final List<Rect> pendingCommentRects;
  final List<(Color, List<Rect>)> remoteSelections;
  final List<Rect> blockSelectionRects;
}

/// Underlay: find matches (`findMatch` / `findMatchActive`), the pending
/// comment range (dashed underline), collaborators' selections (presence
/// color at 20 %, 10 % when unfocused) and the block-selection ring
/// (Write 04 §22.3, §25.3, §33, §34.2).
class WonkyHighlightLayerBuilder implements SuperEditorLayerBuilder {
  const WonkyHighlightLayerBuilder({
    required this.controller,
    required this.theme,
  });

  final WriteEditorController controller;
  final EditorTheme theme;

  /// Find matches measured by the last layout of the layer (tests: only
  /// the ones near the viewport are).
  @visibleForTesting
  static int debugMeasuredFindMatches = 0;

  @override
  ContentLayerWidget build(
    BuildContext context,
    SuperEditorContext editContext,
  ) => _HighlightLayer(controller: controller, theme: theme);
}

/// The same layer for `SuperReader`.
class WonkyReaderHighlightLayerBuilder
    implements SuperReaderDocumentLayerBuilder {
  const WonkyReaderHighlightLayerBuilder({
    required this.controller,
    required this.theme,
  });

  final WriteEditorController controller;
  final EditorTheme theme;

  @override
  ContentLayerWidget build(
    BuildContext context,
    SuperReaderContext readerContext,
  ) => _HighlightLayer(controller: controller, theme: theme);
}

class _HighlightLayer extends DocumentLayoutLayerStatefulWidget {
  const _HighlightLayer({required this.controller, required this.theme});

  final WriteEditorController controller;
  final EditorTheme theme;

  @override
  DocumentLayoutLayerState<_HighlightLayer, _UnderlayData> createState() =>
      _HighlightLayerState();
}

class _HighlightLayerState
    extends DocumentLayoutLayerState<_HighlightLayer, _UnderlayData> {
  @override
  void initState() {
    super.initState();
    widget.controller.view.addListener(_onChange);
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_HighlightLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.view.removeListener(_onChange);
      oldWidget.controller.removeListener(_onChange);
      widget.controller.view.addListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_onScroll);
      _position = position?..addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    widget.controller.view.removeListener(_onChange);
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Viewport (Write 04 §36.2, W-13): highlights are measured only for the
  // visible part of the document plus one screen above and below; scrolling
  // past that measures again.

  ScrollPosition? _position;
  DocumentLayout? _layout;

  /// The document y-range the current layout data covers (null: all).
  (double, double)? _covered;

  void _onScroll() {
    final covered = _covered;
    final layout = _layout;
    if (covered == null || layout == null || !mounted) return;
    final visible = _visible(layout);
    if (visible == null || visible.$1 < covered.$1 || visible.$2 > covered.$2) {
      setState(() {});
    }
  }

  /// The visible document y-range, or null when unknown.
  (double, double)? _visible(DocumentLayout layout) {
    final scrollable = context.findAncestorStateOfType<ScrollableState>();
    final box = scrollable?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final top = layout
        .getDocumentOffsetFromAncestorOffset(box.localToGlobal(Offset.zero))
        .dy;
    return (top, top + box.size.height);
  }

  /// The Delta range `[start, end)` of the blocks in the document y-range
  /// [range].
  static (int, int)? _offsetsIn(
    DocumentLayout layout,
    WriteEditorController controller,
    (double, double) range,
  ) {
    final mirror = controller.mirror;
    final count = mirror.nodeCount;
    if (count == 0) return null;
    // The top of block [index] in document coordinates (null: not laid out).
    double? topOf(int index) {
      final component = layout.getComponentByNodeId(
        mirror.entryAt(index).nodeId,
      );
      final box = component?.context.findRenderObject();
      if (box is! RenderBox || !box.attached) return null;
      return layout
          .getDocumentOffsetFromAncestorOffset(box.localToGlobal(Offset.zero))
          .dy;
    }

    // The last block that starts at or above [y] (binary search: blocks are
    // stacked top to bottom).
    int? indexAt(double y) {
      var lo = 0;
      var hi = count - 1;
      while (lo < hi) {
        final mid = (lo + hi + 1) ~/ 2;
        final top = topOf(mid);
        if (top == null) return null;
        if (top <= y) {
          lo = mid;
        } else {
          hi = mid - 1;
        }
      }
      return lo;
    }

    final i = indexAt(range.$1);
    final j = indexAt(range.$2);
    if (i == null || j == null) return null;
    return (
      mirror.startOfIndex(i),
      mirror.startOfIndex(j) + mirror.entryAt(j).length,
    );
  }

  @override
  _UnderlayData? computeLayoutDataWithDocumentLayout(
    BuildContext contentLayersContext,
    BuildContext documentContext,
    DocumentLayout documentLayout,
  ) {
    final controller = widget.controller;
    final mirror = controller.mirror;
    final view = controller.view;
    final theme = widget.theme;
    List<Rect> rects(HighlightRange range) => DocumentGeometry.rectsForRange(
      documentLayout,
      mirror,
      range.start,
      range.end,
    );

    _layout = documentLayout;
    // Only find matches and collaborators' selections are limited to the
    // viewport; without any, nothing is measured.
    final ranged =
        view.findMatches.isNotEmpty ||
        (view.showRemoteCursors &&
            view.remoteCursors.any((c) => !c.selection.isCollapsed));
    final visible = ranged ? _visible(documentLayout) : null;
    final covered = visible == null
        ? null
        : (
            visible.$1 - (visible.$2 - visible.$1),
            visible.$2 + (visible.$2 - visible.$1),
          );
    final window = covered == null
        ? null
        : _offsetsIn(documentLayout, controller, covered);
    _covered = window == null ? null : covered;
    bool shown(HighlightRange range) =>
        window == null || (range.end >= window.$1 && range.start <= window.$2);

    final find = <Rect>[];
    final active = <Rect>[];
    final matches = view.findMatches;
    var painted = 0;
    for (var i = 0; i < matches.length && painted < 2000; i += 1) {
      if (!shown(matches[i])) continue;
      painted += 1;
      (i == view.activeFindMatch ? active : find).addAll(rects(matches[i]));
    }

    WonkyHighlightLayerBuilder.debugMeasuredFindMatches = painted;
    final remote = <(Color, List<Rect>)>[];
    if (view.showRemoteCursors) {
      var count = 0;
      for (final cursor in view.remoteCursors) {
        if (cursor.selection.isCollapsed || count >= 50) continue;
        if (!shown(
          HighlightRange(cursor.selection.start, cursor.selection.end),
        )) {
          continue;
        }
        count += 1;
        final color = cursor.colorIndex == null
            ? theme.presenceColorFor(cursor.userKey)
            : theme.presenceColors[cursor.colorIndex! %
                  theme.presenceColors.length];
        remote.add((
          cursor.focused ? color : color.withValues(alpha: 0.5),
          rects(HighlightRange(cursor.selection.start, cursor.selection.end)),
        ));
      }
    }

    final blockRects = <Rect>[];
    final selection = controller.selection;
    if (view.blockSelection && selection != null) {
      for (final block in mirror.blocksInSelection(selection)) {
        final rect = documentLayout.getRectForSelection(
          DocumentPosition(
            nodeId: block.id,
            nodePosition: block.node.beginningPosition,
          ),
          DocumentPosition(
            nodeId: block.id,
            nodePosition: block.node.endPosition,
          ),
        );
        if (rect != null) blockRects.add(rect);
      }
    }

    return _UnderlayData(
      findRects: find,
      activeFindRects: active,
      pendingCommentRects: view.pendingComment == null
          ? const []
          : rects(view.pendingComment!),
      remoteSelections: remote,
      blockSelectionRects: blockRects,
    );
  }

  @override
  Widget doBuild(BuildContext context, _UnderlayData? layoutData) {
    if (layoutData == null) return const SizedBox();
    final theme = widget.theme;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: RemoteSelectionPainter(
                selections: layoutData.remoteSelections,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _RectsPainter(
                fills: [
                  (theme.findMatch, layoutData.findRects),
                  (theme.findMatchActive, layoutData.activeFindRects),
                  (
                    theme.selectionColor.withValues(alpha: 0.3),
                    layoutData.blockSelectionRects,
                  ),
                ],
                rings: [(theme.ringColor, layoutData.blockSelectionRects)],
                dashedUnderlines: [
                  (theme.ringColor, layoutData.pendingCommentRects),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RectsPainter extends CustomPainter {
  _RectsPainter({
    required this.fills,
    required this.rings,
    required this.dashedUnderlines,
  });

  final List<(Color, List<Rect>)> fills;
  final List<(Color, List<Rect>)> rings;
  final List<(Color, List<Rect>)> dashedUnderlines;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (color, rects) in fills) {
      final paint = Paint()..color = color;
      for (final rect in rects) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      }
    }
    for (final (color, rects) in rings) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final rect in rects) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(3)),
          paint,
        );
      }
    }
    for (final (color, rects) in dashedUnderlines) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5;
      for (final rect in rects) {
        var x = rect.left;
        while (x < rect.right) {
          final end = (x + 4).clamp(rect.left, rect.right);
          canvas.drawLine(
            Offset(x, rect.bottom),
            Offset(end, rect.bottom),
            paint,
          );
          x += 7;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RectsPainter oldDelegate) => true;
}

/// Overlay: collaborators' carets with name flags (`RemoteCaret` from
/// `wonky_ui`, Write 04 §34.2). Hidden when the collaborator is unfocused;
/// 50 % alpha when idle.
class WonkyRemoteCaretLayerBuilder implements SuperEditorLayerBuilder {
  const WonkyRemoteCaretLayerBuilder({
    required this.controller,
    required this.theme,
  });

  final WriteEditorController controller;
  final EditorTheme theme;

  @override
  ContentLayerWidget build(
    BuildContext context,
    SuperEditorContext editContext,
  ) => _RemoteCaretLayer(controller: controller, theme: theme);
}

class WonkyReaderRemoteCaretLayerBuilder
    implements SuperReaderDocumentLayerBuilder {
  const WonkyReaderRemoteCaretLayerBuilder({
    required this.controller,
    required this.theme,
  });

  final WriteEditorController controller;
  final EditorTheme theme;

  @override
  ContentLayerWidget build(
    BuildContext context,
    SuperReaderContext readerContext,
  ) => _RemoteCaretLayer(controller: controller, theme: theme);
}

class _CaretData {
  const _CaretData(this.cursor, this.rect, this.color);

  final RemoteCursor cursor;
  final Rect rect;
  final Color color;
}

class _RemoteCaretLayer extends DocumentLayoutLayerStatefulWidget {
  const _RemoteCaretLayer({required this.controller, required this.theme});

  final WriteEditorController controller;
  final EditorTheme theme;

  @override
  DocumentLayoutLayerState<_RemoteCaretLayer, List<_CaretData>> createState() =>
      _RemoteCaretLayerState();
}

class _RemoteCaretLayerState
    extends DocumentLayoutLayerState<_RemoteCaretLayer, List<_CaretData>> {
  @override
  void initState() {
    super.initState();
    widget.controller.view.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.view.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  List<_CaretData>? computeLayoutDataWithDocumentLayout(
    BuildContext contentLayersContext,
    BuildContext documentContext,
    DocumentLayout documentLayout,
  ) {
    final view = widget.controller.view;
    if (!view.showRemoteCursors) return const [];
    final mirror = widget.controller.mirror;
    final theme = widget.theme;
    final carets = <_CaretData>[];
    for (final cursor in view.remoteCursors) {
      if (!cursor.focused || carets.length >= 50) continue;
      final offset = cursor.selection.head.clamp(0, mirror.length - 1);
      final rect = DocumentGeometry.caretRect(documentLayout, mirror, offset);
      if (rect == null) continue;
      var color = cursor.colorIndex == null
          ? theme.presenceColorFor(cursor.userKey)
          : theme.presenceColors[cursor.colorIndex! %
                theme.presenceColors.length];
      if (cursor.idle) color = color.withValues(alpha: 0.5);
      carets.add(_CaretData(cursor, rect, color));
    }
    return carets;
  }

  @override
  Widget doBuild(BuildContext context, List<_CaretData>? layoutData) {
    if (layoutData == null || layoutData.isEmpty) return const SizedBox();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final caret in layoutData)
          Positioned(
            key: ValueKey('write.editor.remoteCaret.${caret.cursor.sessionId}'),
            left: caret.rect.left,
            top: caret.rect.top,
            child: RemoteCaret(
              name: caret.cursor.isAgent
                  ? '${caret.cursor.name} ✦'
                  : caret.cursor.name,
              color: caret.color,
              height: caret.rect.height,
              lastActivity: caret.cursor.lastActivity ?? caret.cursor.selection,
            ),
          ),
      ],
    );
  }
}
