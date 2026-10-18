import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../mapping/wonky_schema.dart';
import '../view/editor_view_state.dart';

/// Computes page breaks for the Pages layout (Write 04 §29.3): pages are
/// computed from the laid-out blocks' natural positions, never stored.
///
/// A block that doesn't fit on the current page (and isn't taller than a
/// page) is pushed to the next page by injecting extra top padding
/// ([PaginationStylePhase]); a block that would start in a page's bottom
/// margin or in the gap between pages starts at the next page's content top;
/// headings keep with the next block's first line; oversized blocks overflow
/// across the page seam.
class PaginationController extends ChangeNotifier {
  PaginationController();

  EditorPageSetup _setup = EditorPageSetup.a4;
  double _zoom = 1;

  /// Extra top padding per node id (scaled pixels).
  Map<String, double> _gaps = const {};

  /// The gaps the last styled layout was built with ([markApplied]). Natural
  /// positions are measured against these, not against [_gaps]: a [measure]
  /// that runs before the layout picked up new gaps stays correct.
  Map<String, double> _applied = const {};
  int _pageCount = 1;

  Map<String, double> get gaps => _gaps;

  /// Number of pages after the last layout.
  int get pageCount => _pageCount;

  EditorPageSetup get setup => _setup;
  double get zoom => _zoom;

  /// Page height plus the gap between pages (scaled).
  double get pageStride => (_setup.size.height + _setup.pageGap) * _zoom;

  /// Height of a page's content area (page height minus the top and bottom
  /// margins, scaled): the tallest block that fits on one page.
  double get contentHeight => _setup.contentHeight * _zoom;

  /// The top of page [page]'s content area in document-layout coordinates.
  double contentTopOf(int page) =>
      page * pageStride + _setup.margins.top * _zoom;

  /// The bottom of page [page]'s content area in document-layout coordinates.
  double contentBottomOf(int page) => contentTopOf(page) + contentHeight;

  void configure(EditorPageSetup setup, double zoom) {
    if (setup == _setup && zoom == _zoom) return;
    _setup = setup;
    _zoom = zoom;
    _gaps = const {};
    notifyListeners();
  }

  /// Records the gaps the document layout was styled with (called by
  /// [PaginationStylePhase]).
  void markApplied(Map<String, double> gaps) => _applied = gaps;

  /// Natural geometry of each node at the last [measure], by node instance
  /// (super_editor nodes are immutable: the same instance is the same
  /// content), valid for [_measuredWith].
  Map<DocumentNode, _Measured> _measured = Map.identity();
  Object? _measuredWith;

  /// Number of nodes the last [measure] asked the layout for (tests).
  @visibleForTesting
  int debugLastQueries = 0;

  /// Measures the laid-out [document] and recomputes the page breaks.
  /// Returns whether the injected gaps changed (the layout must be redone and
  /// measured again).
  ///
  /// Incremental (Write 04 §36): a node whose instance and component size
  /// are unchanged since the last measure keeps its natural rect, shifted by
  /// how far the nodes above it moved; only changed nodes (and the first
  /// unchanged node after them, to learn that shift) are measured through
  /// the layout. A caret move measures nothing. [componentSize] reports a
  /// node's laid-out size (default: its component's render box).
  bool measure(
    DocumentLayout layout,
    Document document, {
    Size? Function(String nodeId)? componentSize,
  }) {
    componentSize ??= (id) => _componentSize(layout, id);
    final contentHeight = this.contentHeight;
    final nodes = document.toList();

    // Natural rects: the laid-out rects minus every gap applied above them.
    // For keep-with-next, also the natural bottom of each block's first line.
    final natural = List<Rect?>.filled(nodes.length, null);
    final firstLineBottom = List<double?>.filled(nodes.length, null);
    final key = (layout, _setup, _zoom);
    final previous = key == _measuredWith ? _measured : null;
    final measured = Map<DocumentNode, _Measured>.identity();
    var queries = 0;
    var appliedShift = 0.0;
    // How far unchanged nodes moved since the last measure (null: unknown
    // until the next unchanged node is measured). Nothing is above the
    // first node.
    double? moved = previous == null ? null : 0;
    for (var i = 0; i < nodes.length; i += 1) {
      final node = nodes[i];
      final before = previous?[node];
      final size = componentSize(node.id);
      final unchanged = before != null && size != null && before.size == size;
      if (unchanged && moved != null) {
        final rect = before.rect;
        if (rect == null) {
          measured[node] = before;
          continue;
        }
        appliedShift += _applied[node.id] ?? 0;
        natural[i] = rect.translate(0, moved);
        firstLineBottom[i] = before.firstLineBottom! + moved;
        measured[node] = _Measured(natural[i], firstLineBottom[i], size);
        continue;
      }
      queries += 1;
      final begin = DocumentPosition(
        nodeId: node.id,
        nodePosition: node.beginningPosition,
      );
      final rect = layout.getRectForSelection(
        begin,
        DocumentPosition(nodeId: node.id, nodePosition: node.endPosition),
      );
      if (rect == null) {
        measured[node] = _Measured(null, null, size);
        moved = null;
        continue;
      }
      appliedShift += _applied[node.id] ?? 0;
      natural[i] = rect.translate(0, -appliedShift);
      final firstLine = layout.getRectForPosition(begin);
      firstLineBottom[i] = (firstLine?.bottom ?? rect.bottom) - appliedShift;
      measured[node] = _Measured(natural[i], firstLineBottom[i], size);
      final beforeRect = before?.rect;
      moved = unchanged && beforeRect != null
          ? natural[i]!.top - beforeRect.top
          : null;
    }
    _measured = measured;
    _measuredWith = key;
    debugLastQueries = queries;

    final newGaps = <String, double>{};
    var shift = 0.0;
    var page = 0;
    for (var i = 0; i < nodes.length; i += 1) {
      final rect = natural[i];
      if (rect == null) continue;
      final node = nodes[i];
      final height = rect.height;
      var top = rect.top + shift;
      var bottom = rect.bottom + shift;

      while (top >= contentBottomOf(page)) {
        page += 1;
      }
      var gap = 0.0;
      final contentTop = contentTopOf(page);
      if (top < contentTop - 0.5) {
        // The block would start in the bottom margin of the previous page or
        // in the gap between pages: it starts at this page's content top.
        gap = contentTop - top;
        top += gap;
        bottom += gap;
      }

      var needed = bottom;
      final isHeading =
          node is ParagraphNode &&
          headingLevelOf(node.getMetadataValue(NodeMetadata.blockType)) != null;
      if (isHeading) {
        // Keep with next: the next block's first line must fit, too.
        final next = _nextLaidOut(natural, i);
        if (next != null) {
          final nextLine = firstLineBottom[next]! + shift + gap;
          if (nextLine > needed) needed = nextLine;
        }
      }
      if (needed > contentBottomOf(page) + 0.5 &&
          height <= contentHeight &&
          top > contentTop + 0.5) {
        final push = contentTopOf(page + 1) - top;
        gap += push;
        page += 1;
        top += push;
        bottom += push;
      }
      if (gap > 0) {
        newGaps[node.id] = gap;
        shift += gap;
      }
      while (bottom > contentBottomOf(page) + 0.5 && height > contentHeight) {
        // Oversized block: it overflows across the seam.
        page += 1;
      }
    }

    final changed = !_sameGaps(newGaps, _gaps);
    if (changed) _gaps = newGaps;
    final count = page + 1;
    if (changed || count != _pageCount) {
      _pageCount = count;
      notifyListeners();
    }
    return changed;
  }

  /// The laid-out size of [nodeId]'s component (its height changes when an
  /// image loads, a font arrives or the width changes, without a new node).
  static Size? _componentSize(DocumentLayout layout, String nodeId) {
    final component = layout.getComponentByNodeId(nodeId);
    if (component == null || !component.mounted) return null;
    final box = component.context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : null;
  }

  static int? _nextLaidOut(List<Rect?> rects, int index) {
    for (var j = index + 1; j < rects.length; j += 1) {
      if (rects[j] != null) return j;
    }
    return null;
  }

  static bool _sameGaps(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || (other - entry.value).abs() > 0.5) return false;
    }
    return true;
  }
}

/// What [PaginationController.measure] learned about one node.
class _Measured {
  const _Measured(this.rect, this.firstLineBottom, this.size);

  /// Natural rect (without injected gaps); null when not laid out.
  final Rect? rect;
  final double? firstLineBottom;

  /// Component size when measured (null when unknown).
  final Size? size;
}

/// Injects the page-break gaps of a [PaginationController] as extra top
/// padding.
///
/// The phase lives as long as its [pagination] (both are owned by the editor)
/// and outlives layout presenters: `super_editor` disposes every style phase
/// when it recreates its presenter (on any stylesheet or zoom change) and
/// then hands the same phase to the new presenter. So [dispose] keeps the
/// pagination listener; otherwise new gaps would never reach the layout
/// after the first presenter change.
class PaginationStylePhase extends SingleColumnLayoutStylePhase {
  PaginationStylePhase(this.pagination) {
    pagination.addListener(markDirty);
  }

  final PaginationController pagination;

  /// Stops listening to [pagination] (when the editor is disposed).
  void close() => pagination.removeListener(markDirty);

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    final gaps = pagination.gaps;
    pagination.markApplied(gaps);
    if (gaps.isEmpty) return viewModel;
    return SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: [
        for (final model in viewModel.componentViewModels)
          if (gaps[model.nodeId] case final gap?)
            (model.copy()
              ..padding = model.padding.add(EdgeInsets.only(top: gap)))
          else
            model,
      ],
    );
  }
}

/// Paints page cards, header/footer text and page numbers under the document
/// in the Pages layout (Write 04 §29.2).
class PageChromePainter extends CustomPainter {
  PageChromePainter({
    required this.pagination,
    required this.paperColor,
    required this.borderColor,
    required this.textStyle,
  }) : super(repaint: pagination);

  final PaginationController pagination;
  final Color paperColor;
  final Color borderColor;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final setup = pagination.setup;
    final zoom = pagination.zoom;
    final pageSize = setup.size * zoom;
    final stride = pagination.pageStride;
    final count = pagination.pageCount;
    final paper = Paint()..color = paperColor;
    // On dark paper a drop shadow is invisible against the (darker) canvas,
    // so the page edge gets a light hairline instead (Write 06 §9).
    final dark = paperColor.computeLuminance() < 0.2;
    final shadow = Paint()
      ..color = dark ? const Color(0x66000000) : const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final border = Paint()
      ..color = dark ? const Color(0x1fffffff) : borderColor
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < count; i += 1) {
      final rect = Offset(0, i * stride) & pageSize;
      canvas
        ..drawRect(rect.translate(0, 2), shadow)
        ..drawRect(rect, paper)
        ..drawRect(rect.deflate(0.5), border);
      _text(
        canvas,
        setup.headerText,
        i,
        count,
        Offset(
          rect.left + setup.margins.left * zoom,
          rect.top + setup.margins.top * zoom / 2 - 8,
        ),
      );
      _text(
        canvas,
        setup.footerText,
        i,
        count,
        Offset(
          rect.left + setup.margins.left * zoom,
          rect.bottom - setup.margins.bottom * zoom / 2 - 8,
        ),
      );
    }
  }

  void _text(Canvas canvas, String template, int page, int pages, Offset at) {
    if (template.isEmpty) return;
    final text = template
        .replaceAll('{page}', '${page + 1}')
        .replaceAll('{pages}', '$pages');
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(PageChromePainter oldDelegate) =>
      oldDelegate.paperColor != paperColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.pagination != pagination;
}
