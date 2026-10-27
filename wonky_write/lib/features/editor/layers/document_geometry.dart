import 'package:flutter/painting.dart';
import 'package:super_editor/super_editor.dart';

import '../mapping/document_mirror.dart';
import '../model/document_queries.dart';

/// Geometry helpers over a laid-out document (Write 04 §25.3, §34.2).
abstract final class DocumentGeometry {
  /// The position before the character under [offset] (document
  /// coordinates): a click resolves to the nearest caret position, which is
  /// after the character when the click is on its right half (or on the gap
  /// after it: an arrow link's arrow). For what a click is *on*, like a link.
  static DocumentPosition? characterAt(DocumentLayout layout, Offset offset) {
    final position = layout.getDocumentPositionNearestToOffset(offset);
    final p = position?.nodePosition;
    if (position == null || p is! TextNodePosition || p.offset == 0) {
      return position;
    }
    final before = DocumentPosition(
      nodeId: position.nodeId,
      nodePosition: TextNodePosition(offset: p.offset - 1),
    );
    final box = layout.getRectForSelection(before, position);
    return box != null && box.contains(offset) ? before : position;
  }

  /// Per-line rectangles (document coordinates) covering Delta `[start, end)`.
  /// Embeds contribute their whole box. Limited to [maxRects].
  static List<Rect> rectsForRange(
    DocumentLayout layout,
    DocumentMirror mirror,
    int start,
    int end, {
    int maxRects = 400,
  }) {
    final rects = <Rect>[];
    if (end <= start || mirror.nodeCount == 0) return rects;
    for (final block in mirror.blocksIn(start, end)) {
      if (rects.length >= maxRects) break;
      final node = block.node;
      if (node is! TextNode) {
        final rect = layout.getRectForSelection(
          DocumentPosition(
            nodeId: node.id,
            nodePosition: const UpstreamDownstreamNodePosition.upstream(),
          ),
          DocumentPosition(
            nodeId: node.id,
            nodePosition: const UpstreamDownstreamNodePosition.downstream(),
          ),
        );
        if (rect != null) rects.add(rect);
        continue;
      }
      final textLength = node.text.length;
      final from = (start - block.start).clamp(0, textLength);
      final to = (end - block.start).clamp(0, textLength);
      if (to <= from) continue;
      rects.addAll(
        _lineRects(layout, node.id, from, to, maxRects - rects.length),
      );
    }
    return rects;
  }

  static List<Rect> _lineRects(
    DocumentLayout layout,
    String nodeId,
    int from,
    int to,
    int max,
  ) {
    final rects = <Rect>[];
    final component = layout.getComponentByNodeId(nodeId);
    DocumentPosition at(int offset) => DocumentPosition(
      nodeId: nodeId,
      nodePosition: TextNodePosition(offset: offset),
    );
    if (component is! TextComposable) {
      final rect = layout.getRectForSelection(at(from), at(to));
      if (rect != null) rects.add(rect);
      return rects;
    }
    final composable = component as TextComposable;
    var cursor = from;
    var guard = 0;
    while (cursor < to && guard < max) {
      guard += 1;
      final lineEnd = composable
          .getPositionAtEndOfLine(TextNodePosition(offset: cursor))
          .offset;
      final segmentEnd = lineEnd <= cursor ? to : (lineEnd < to ? lineEnd : to);
      final rect = layout.getRectForSelection(at(cursor), at(segmentEnd));
      if (rect != null && rect.width > 0) rects.add(rect);
      if (segmentEnd >= to) break;
      final next = composable.getPositionOneLineDown(
        TextNodePosition(offset: cursor),
      );
      if (next == null) break;
      final nextStart = composable.getPositionAtStartOfLine(next).offset;
      cursor = nextStart > segmentEnd ? nextStart : segmentEnd;
    }
    return rects;
  }

  /// The caret rectangle (document coordinates) at Delta [offset].
  static Rect? caretRect(
    DocumentLayout layout,
    DocumentMirror mirror,
    int offset,
  ) {
    final position = mirror.positionAt(offset);
    if (position == null) return null;
    // The caret's edge: as tall as the text beside it, like the local caret
    // (super_editor patch SE-11).
    final rect =
        layout.getEdgeForPosition(position) ??
        layout.getRectForPosition(position);
    if (rect == null) return null;
    return Rect.fromLTWH(rect.left, rect.top, 2, rect.height);
  }
}
