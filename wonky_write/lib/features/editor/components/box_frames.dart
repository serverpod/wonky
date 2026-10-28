import 'package:flutter/material.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show BoxFrame, BoxType, Boxes, CalloutVariant, CaseTransform;

import '../../../l10n/write_l10n.dart';
import '../mapping/wonky_schema.dart';
import '../styles/editor_theme.dart';
import '../styles/wonky_style.dart';
import 'editor_services.dart';
import 'wonky_components.dart';

/// Shared state of the container frames of one editor (Write 11 §7.2–7.3):
/// the block spacing [BoxStylePhase] moved inside the frames, and which
/// details are collapsed (a per-user view state, not synced).
class BoxFrameLayout extends ChangeNotifier {
  /// The stylesheet padding of each boxed node, drawn inside its frames.
  final innerPadding = <String, EdgeInsets>{};

  /// Details the user collapsed (`true`) or expanded (`false`).
  final _overrides = <String, bool>{};

  /// Whether details start collapsed: in Viewing mode (Write 11 §7.3).
  bool get collapseByDefault => _collapseByDefault;
  bool _collapseByDefault = false;
  set collapseByDefault(bool value) {
    if (value == _collapseByDefault) return;
    _collapseByDefault = value;
    notifyListeners();
  }

  /// Whether the details container [frameId] is collapsed.
  bool isCollapsed(String frameId) => _overrides[frameId] ?? _collapseByDefault;

  /// Collapses or expands the details container [frameId].
  void setCollapsed(String frameId, bool collapsed) {
    if (isCollapsed(frameId) == collapsed) return;
    _overrides[frameId] = collapsed;
    notifyListeners();
  }

  /// Expands the collapsed details containers whose body [node] is in (the
  /// caret or the active find match moved there); a summary keeps its own
  /// details as they are.
  void reveal(Document document, DocumentNode node) {
    final frames = boxOf(node);
    expandAll([
      for (var d = 0; d < frames.length; d++)
        if (frames[d].type == BoxType.details &&
            isCollapsed(frames[d].id) &&
            !isDetailsSummaryNode(document, node, d))
          frames[d],
    ]);
  }

  /// Expands every collapsed details container in [frames] (the caret or a
  /// find match moved into it). Returns whether anything changed.
  bool expandAll(Iterable<BoxFrame> frames) {
    var changed = false;
    for (final f in frames) {
      if (!isCollapsed(f.id)) continue;
      _overrides[f.id] = false;
      changed = true;
    }
    if (changed) notifyListeners();
    return changed;
  }
}

/// Whether [node] is the summary line of the details container at [depth] of
/// its frames: the container's first line, a level-3 heading directly in it
/// (Write 11 §2.2).
bool isDetailsSummaryNode(Document document, DocumentNode node, int depth) {
  final frames = boxOf(node);
  if (depth >= frames.length || frames[depth].type != BoxType.details) {
    return false;
  }
  if (frames.length != depth + 1) return false;
  if (!_isFirstAt(document, node, frames, depth)) return false;
  return node is ParagraphNode &&
      headingLevelOf(node.getMetadataValue(NodeMetadata.blockType)) == 3;
}

bool _isFirstAt(
  Document document,
  DocumentNode node,
  List<BoxFrame> frames,
  int depth,
) => !Boxes.sameAt(boxOf(document.getNodeBeforeById(node.id)), frames, depth);

bool _isLastAt(
  Document document,
  DocumentNode node,
  List<BoxFrame> frames,
  int depth,
) => !Boxes.sameAt(boxOf(document.getNodeAfterById(node.id)), frames, depth);

/// The frame of the container at [depth] that [node] is in, as its
/// container's first line sees it (Write 11 §2.2: properties come from the
/// first line).
BoxFrame containerFrameOf(Document document, DocumentNode node, int depth) {
  final frames = boxOf(node);
  DocumentNode first = node;
  while (true) {
    final previous = document.getNodeBeforeById(first.id);
    if (previous == null || !Boxes.sameAt(boxOf(previous), frames, depth)) {
      break;
    }
    first = previous;
  }
  return boxOf(first)[depth];
}

/// Moves the vertical block spacing of nodes in containers inside their
/// frames so that a container is one continuous box: the stylesheet padding
/// of a boxed node is recorded in [BoxFrameLayout.innerPadding] (drawn by
/// [BoxFrameComponentBuilder]) and replaced by the outermost container's
/// space before and after. Runs before pagination.
class BoxStylePhase extends SingleColumnLayoutStylePhase {
  BoxStylePhase(this.layout, {required this.wonkyStyle, required this.zoom});

  /// The editor controller's layout (replaced with the controller).
  BoxFrameLayout layout;

  /// Updated by the editor when the theme changes.
  WonkyEditorStyle wonkyStyle;

  /// Updated by the editor when the zoom changes.
  double zoom;

  /// The body font size in px at 100 % (details summaries use it).
  double bodyFontSize = 14.67;

  /// Takes a new theme style or zoom. Called while building: a theme or
  /// zoom change also changes the stylesheet, which restyles everything, so
  /// the phase doesn't mark itself dirty (that would notify during build).
  void update(WonkyEditorStyle style, double zoom, double bodyFontSize) {
    wonkyStyle = style;
    this.zoom = zoom;
    this.bodyFontSize = bodyFontSize;
  }

  /// Summary text style builders by the stylesheet's builder (stable
  /// instances keep view models equal between passes).
  final _summaryBuilders = Expando<AttributionStyleBuilder>();

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    layout.innerPadding.clear();
    var changed = false;
    final models = <SingleColumnLayoutComponentViewModel>[];
    for (final model in viewModel.componentViewModels) {
      final node = document.getNodeById(model.nodeId);
      final frames = boxOf(node);
      if (node == null || frames.isEmpty) {
        models.add(model);
        continue;
      }
      // Containers have their own padding: no block spacing at their edges.
      final inner = model.padding.resolve(TextDirection.ltr);
      final innermost = frames.length - 1;
      final summary = isDetailsSummaryNode(document, node, innermost);
      layout.innerPadding[node.id] = inner.copyWith(
        top: _isFirstAt(document, node, frames, innermost) ? 0 : inner.top,
        bottom: _isLastAt(document, node, frames, innermost) ? 0 : inner.bottom,
        // Room for the chevron.
        right: summary ? inner.right + 28 * zoom : inner.right,
      );
      final outer = wonkyStyle.frameOf(containerFrameOf(document, node, 0));
      final padding = EdgeInsets.only(
        top: _isFirstAt(document, node, frames, 0)
            ? outer.spaceBefore * zoom
            : 0,
        bottom: _isLastAt(document, node, frames, 0)
            ? outer.spaceAfter * zoom
            : 0,
      );
      if (summary && model is TextComponentViewModel) {
        changed = true;
        final copy = model.copy()..padding = padding;
        final base = model.textStyleBuilder;
        (copy as TextComponentViewModel).textStyleBuilder =
            _summaryBuilders[base] ??= (attributions) =>
                base(attributions).copyWith(
                  fontSize: bodyFontSize * zoom,
                  fontWeight: wonkyStyle.detailsSummaryWeight,
                  height: 1.4,
                );
        models.add(copy);
        continue;
      }
      if (padding == model.padding) {
        models.add(model);
        continue;
      }
      changed = true;
      models.add(model.copy()..padding = padding);
    }
    if (!changed) return viewModel;
    return SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: models,
    );
  }
}

/// Wraps the components of [inner] in the frames of their node's containers
/// (Write 11 §7.2): for each container, outermost first, its background,
/// borders and inner padding; the container's first line also draws its top
/// edge and header (a callout's label), the last one its bottom edge. A
/// collapsed details body lays out at zero height.
class BoxFrameComponentBuilder implements ComponentBuilder {
  const BoxFrameComponentBuilder(
    this.inner, {
    required this.document,
    required this.layout,
    required this.theme,
    required this.zoom,
    this.callbacks = const EditorBlockCallbacks(),
    this.editable = true,
  });

  final ComponentBuilder inner;
  final Document document;
  final BoxFrameLayout layout;
  final EditorTheme theme;
  final double zoom;
  final EditorBlockCallbacks callbacks;
  final bool editable;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    final component = inner.createComponent(componentContext, viewModel);
    if (component == null) return null;
    final node = document.getNodeById(viewModel.nodeId);
    final frames = boxOf(node);
    // Table cells and grid items are framed as a group ([frameGroup]).
    if (node == null || frames.isEmpty || isCellNode(node)) return component;
    // Collapsing a details container changes no view model: the frames
    // listen to the layout instead.
    // Nor does a frame changed in place (a callout's type or title): the
    // node's frames are watched too.
    return EditorNodeWatcher(
      document: document,
      nodeId: node.id,
      builder: (_) => ListenableBuilder(
        listenable: layout,
        builder: (context, _) {
          final current = document.getNodeById(node.id) ?? node;
          final currentFrames = boxOf(current);
          return currentFrames.isEmpty
              ? component
              : _frames(current, currentFrames, component);
        },
      ),
    );
  }

  /// [child] (a table or grid, Write 12 §3.2) in the frames of the
  /// containers of its [first] and [last] nodes, with the block spacing
  /// inside them.
  Widget frameGroup(DocumentNode first, DocumentNode last, Widget child) {
    final frames = boxOf(first);
    if (frames.isEmpty) return child;
    // The outermost container's spacing (for other nodes their padding,
    // [BoxStylePhase]).
    final outer = theme.wonky.frameOf(containerFrameOf(document, first, 0));
    return Padding(
      padding: EdgeInsets.only(
        top: _isFirstAt(document, first, frames, 0)
            ? outer.spaceBefore * zoom
            : 0,
        bottom: _isLastAt(document, last, frames, 0)
            ? outer.spaceAfter * zoom
            : 0,
      ),
      child: ListenableBuilder(
        listenable: layout,
        builder: (context, _) => _frames(first, frames, child, last: last),
      ),
    );
  }

  Widget _frames(
    DocumentNode node,
    List<BoxFrame> frames,
    Widget component, {
    DocumentNode? last,
  }) {
    final end = last ?? node;
    final style = theme.wonky;
    // The summary of a collapsed details ends its box: no block spacing
    // below it inside the frame, whose bottom padding follows directly.
    final endsCollapsed = [
      for (var depth = 0; depth < frames.length; depth++)
        if (frames[depth].type == BoxType.details &&
            layout.isCollapsed(frames[depth].id) &&
            _isFirstAt(document, node, frames, depth))
          depth,
    ].isNotEmpty;
    final inner = layout.innerPadding[node.id] ?? EdgeInsets.zero;
    Widget child = Padding(
      padding: endsCollapsed ? inner.copyWith(bottom: 0) : inner,
      child: component,
    );
    var collapsed = false;
    for (var depth = frames.length - 1; depth >= 0; depth--) {
      final frame = containerFrameOf(document, node, depth);
      final first = _isFirstAt(document, node, frames, depth);
      final collapsedSummary =
          frame.type == BoxType.details &&
          first &&
          layout.isCollapsed(frame.id);
      // A collapsed details ends with its summary: bottom border and padding.
      final last = collapsedSummary || _isLastAt(document, end, frames, depth);
      if (frame.type == BoxType.details &&
          layout.isCollapsed(frame.id) &&
          !(first && isDetailsSummaryNode(document, node, depth))) {
        collapsed = true;
      }
      child = _FrameSegment(
        key: ValueKey('write.editor.box.${frame.id}.${node.id}'),
        nodeId: node.id,
        depth: depth,
        frame: frame,
        frameStyle: style.frameOf(frame),
        style: style,
        bodyStyle: theme.body,
        zoom: zoom,
        first: first,
        last: last,
        // The outermost container's spacing is the node's own padding.
        margins: depth > 0,
        collapsedSummary: collapsedSummary,
        layout: layout,
        callbacks: callbacks,
        editable: editable,
        child: child,
      );
    }
    if (collapsed) {
      // Laid out (super_editor keeps measuring it) but zero height, clipped.
      return ClipRect(child: Align(heightFactor: 0, child: child));
    }
    return child;
  }
}

class _FrameSegment extends StatelessWidget {
  const _FrameSegment({
    super.key,
    required this.nodeId,
    required this.depth,
    required this.frame,
    required this.frameStyle,
    required this.style,
    required this.bodyStyle,
    required this.zoom,
    required this.first,
    required this.last,
    required this.margins,
    required this.collapsedSummary,
    required this.layout,
    required this.callbacks,
    required this.editable,
    required this.child,
  });

  final String nodeId;
  final int depth;
  final BoxFrame frame;
  final FrameStyle frameStyle;
  final WonkyEditorStyle style;
  final TextStyle bodyStyle;
  final double zoom;
  final bool first;
  final bool last;
  final bool margins;
  final bool collapsedSummary;
  final BoxFrameLayout layout;
  final EditorBlockCallbacks callbacks;
  final bool editable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final f = frameStyle;
    final bw = f.borderColor == null ? 0.0 : f.borderWidth * zoom;
    final pad = f.padding * zoom;
    final header = first && frame.type == BoxType.callout
        ? _CalloutHeader(
            nodeId: nodeId,
            depth: depth,
            frame: frame,
            style: style,
            fontSize: (bodyStyle.fontSize ?? 14.67) * zoom,
            callbacks: editable ? callbacks : const EditorBlockCallbacks(),
          )
        : null;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        pad.left + bw,
        first ? pad.top + bw : 0,
        pad.right + bw,
        last ? pad.bottom + bw : 0,
      ),
      child: header == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [header, child],
            ),
    );
    final l = writeL10n(context);
    Widget? chrome;
    if (first) {
      final buttons = <Widget>[
        if (editable && callbacks.onBoxMenu != null) ...[
          EditorChromeButton(
            key: ValueKey('write.editor.box.menu.${frame.id}'),
            icon: LucideIcons.ellipsis,
            tooltip: l.editorContainerMenu,
            onTap: (rect) => callbacks.onBoxMenu!(nodeId, depth, rect),
          ),
        ],
      ];
      if (buttons.isNotEmpty) {
        chrome = Row(mainAxisSize: MainAxisSize.min, children: buttons);
      }
    }
    Widget box = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _FramePainter(
                background: f.background,
                borderColor: f.borderColor,
                borderWidth: bw,
                radius: f.radius * zoom,
                first: first,
                last: last,
                shadow: f.shadow,
              ),
            ),
          ),
        ),
        content,
      ],
    );
    if (first && frame.type == BoxType.details) {
      // The disclosure chevron at the right of the summary.
      final size = 20 * zoom;
      box = Stack(
        clipBehavior: Clip.none,
        children: [
          box,
          Positioned(
            top: pad.top + bw + 1 * zoom,
            right: pad.right + bw,
            child: _Tappable(
              key: ValueKey('write.editor.box.toggle.${frame.id}'),
              tooltip: collapsedSummary
                  ? l.editorDetailsExpand
                  : l.editorDetailsCollapse,
              onTap: () => layout.setCollapsed(frame.id, !collapsedSummary),
              child: AnimatedRotation(
                turns: collapsedSummary ? -0.25 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: size,
                  color: style.chevronColor,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (chrome != null) {
      box = EditorHoverChrome(chrome: chrome, child: box);
    }
    if (!margins) return box;
    return Padding(
      padding: EdgeInsets.only(
        top: first ? f.spaceBefore * zoom : 0,
        bottom: last ? f.spaceAfter * zoom : 0,
      ),
      child: box,
    );
  }
}

/// A callout's label row: the type icon (tap: pick the type) and the title
/// or type label (tap: edit the title).
class _CalloutHeader extends StatelessWidget {
  const _CalloutHeader({
    required this.nodeId,
    required this.depth,
    required this.frame,
    required this.style,
    required this.fontSize,
    required this.callbacks,
  });

  final String nodeId;
  final int depth;
  final BoxFrame frame;
  final WonkyEditorStyle style;
  final double fontSize;
  final EditorBlockCallbacks callbacks;

  static IconData iconOf(CalloutVariant? variant) => switch (variant) {
    CalloutVariant.tip => LucideIcons.lightbulb,
    CalloutVariant.note => LucideIcons.messageSquareMore,
    CalloutVariant.warning ||
    CalloutVariant.caution => LucideIcons.triangleAlert,
    CalloutVariant.danger => LucideIcons.octagonAlert,
    _ => LucideIcons.info,
  };

  @override
  Widget build(BuildContext context) {
    final colors = style.calloutColors(frame.variant);
    final size = fontSize * style.calloutTitleSizeRatio;
    var label = frame.calloutLabel;
    label = switch (style.calloutTitleCase) {
      CaseTransform.uppercase => label.toUpperCase(),
      CaseTransform.lowercase => label.toLowerCase(),
      _ => label,
    };
    Rect rectOf(BuildContext c) {
      final box = c.findRenderObject() as RenderBox?;
      return box == null
          ? Rect.zero
          : box.localToGlobal(Offset.zero) & box.size;
    }

    final l = writeL10n(context);
    return Padding(
      padding: EdgeInsets.only(bottom: size * 0.6),
      child: Row(
        children: [
          Builder(
            builder: (c) => _Tappable(
              key: ValueKey('write.editor.box.variant.${frame.id}'),
              tooltip: l.editorCalloutType,
              onTap: callbacks.onCalloutVariantTap == null
                  ? null
                  : () => callbacks.onCalloutVariantTap!(
                      nodeId,
                      depth,
                      rectOf(c),
                    ),
              child: Icon(
                iconOf(frame.variant),
                size: size * 1.45,
                color: colors.title,
              ),
            ),
          ),
          SizedBox(width: size * 0.5),
          Flexible(
            child: Builder(
              builder: (c) => _Tappable(
                key: ValueKey('write.editor.box.title.${frame.id}'),
                tooltip: l.editorCalloutEditTitle,
                onTap: callbacks.onBoxTitleTap == null
                    ? null
                    : () => callbacks.onBoxTitleTap!(nodeId, depth, rectOf(c)),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: null,
                    fontSize: size,
                    fontWeight: style.calloutTitleWeight,
                    letterSpacing: size * 0.04,
                    color: colors.title,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tappable extends StatelessWidget {
  const _Tappable({
    super.key,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// Paints one node's part of a container: the fill and the border, with
/// the top edge and corners only on the first part and the bottom ones only
/// on the last (the rounded rectangle extends past the hidden edges and is
/// clipped).
class _FramePainter extends CustomPainter {
  _FramePainter({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
    required this.radius,
    required this.first,
    required this.last,
    required this.shadow,
  });

  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final bool first;
  final bool last;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final extend = radius + borderWidth * 2 + 2;
    final rect = Rect.fromLTRB(
      0,
      first ? 0 : -extend,
      size.width,
      last ? size.height : size.height + extend,
    );
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(radius),
    );
    if (shadow && last) {
      canvas
        ..save()
        ..clipRect(
          Rect.fromLTRB(
            -4,
            size.height - radius,
            size.width + 4,
            size.height + 4,
          ),
        )
        ..drawRRect(
          rrect.shift(const Offset(0, 1)),
          Paint()
            ..color = const Color(0x14000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        )
        ..restore();
    }
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    if (background != null) {
      canvas.drawRRect(rrect, Paint()..color = background!);
    }
    if (borderColor != null && borderWidth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
    canvas.restore();
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.background != background ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.radius != radius ||
      old.first != first ||
      old.last != last ||
      old.shadow != shadow;
}
