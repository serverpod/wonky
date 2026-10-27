import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show kDoubleTapSlop, kDoubleTapTimeout, kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show BoxHitTestResult, RenderProxyBox;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../../../l10n/write_l10n.dart';

import '../mapping/wonky_embed_node.dart';
import '../mapping/wonky_schema.dart';
import '../model/code_languages.dart';
import '../model/embeds.dart';
import '../styles/editor_theme.dart';
import 'editor_services.dart';
import 'image_size_cache.dart';

/// Stable widget keys (specs/15 §7).
abstract final class WonkyEditorKeys {
  static const editor = ValueKey<String>('write.editor');
  static const codeBlock = 'write.editor.codeBlock';
  static const codeLanguageChip = 'write.editor.codeLanguage';
  static const codeCopy = 'write.editor.codeCopy';
  static const tableEdit = 'write.editor.tableEdit';
  static const imageRetry = 'write.editor.imageRetry';
  static const imageUploadFailed = 'write.editor.imageUploadFailed';
  static const imageOutOfStorage = 'write.editor.imageOutOfStorage';
  static const imageUploadRetry = 'write.editor.imageUploadRetry';
  static const imageUploadRemove = 'write.editor.imageUploadRemove';
}

// -----------------------------------------------------------------------------
// Images (Write 04 §17.3).

class WonkyImageViewModel extends SingleColumnLayoutComponentViewModel
    with SelectionAwareViewModelMixin {
  WonkyImageViewModel({
    required super.nodeId,
    super.createdAt,
    super.maxWidth,
    super.padding = EdgeInsets.zero,
    required this.src,
    required this.alt,
    this.title,
    DocumentNodeSelection? selection,
    Color selectionColor = Colors.transparent,
  }) {
    this.selection = selection;
    this.selectionColor = selectionColor;
  }

  String src;
  String alt;
  String? title;

  @override
  WonkyImageViewModel copy() => WonkyImageViewModel(
    nodeId: nodeId,
    maxWidth: maxWidth,
    padding: padding,
    src: src,
    alt: alt,
    title: title,
    selection: selection,
    selectionColor: selectionColor,
  )..opacity = opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is WonkyImageViewModel &&
          other.src == src &&
          other.alt == alt &&
          other.title == title &&
          other.selection == selection &&
          other.selectionColor == selectionColor;

  @override
  int get hashCode => Object.hash(super.hashCode, src, alt, title, selection);
}

/// Renders image embeds: `wonky-file://` through [EditorImageServices], upload
/// progress / pending / failed / broken states, alt text as semantics label,
/// and the block-selection ring.
class WonkyImageComponentBuilder implements ComponentBuilder {
  const WonkyImageComponentBuilder({
    required this.services,
    required this.theme,
    this.callbacks = const EditorBlockCallbacks(),
    this.editable = true,
    this.maxHeight,
  });

  final EditorImageServices services;
  final EditorTheme theme;
  final EditorBlockCallbacks callbacks;

  /// In read-only views a click opens the lightbox
  /// ([EditorBlockCallbacks.onImageTap]).
  final bool editable;

  /// The tallest an image is displayed (scaled down, preserving its aspect
  /// ratio): the page content height in Pages mode, so an image always fits
  /// on one page (§17.3, §29.3). `null`: unbounded (Pageless).
  final double? maxHeight;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! ImageNode) return null;
    final data = EmbedNodes.embedDataOf(node);
    return WonkyImageViewModel(
      nodeId: node.id,
      src: node.imageUrl,
      alt: node.altText,
      title: data?['title'] as String?,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! WonkyImageViewModel) return null;
    Widget imageGestures(String nodeId, {required Widget child}) {
      if (editable) {
        // A click selects the image (the interactor), a double click opens
        // its dialog.
        final onDoubleTap = callbacks.onImageDoubleTap;
        return EditorBlockContent(
          onDoubleTap: onDoubleTap == null ? null : () => onDoubleTap(nodeId),
          ignoreChild: false,
          child: child,
        );
      }
      final onTap = callbacks.onImageTap;
      return GestureDetector(
        onTap: onTap == null ? null : () => onTap(nodeId),
        child: child,
      );
    }

    final selection =
        viewModel.selection?.nodeSelection as UpstreamDownstreamNodeSelection?;
    final isSelected = selection != null && !selection.isCollapsed;
    return Semantics(
      image: true,
      label: viewModel.alt.isEmpty
          ? writeL10n(componentContext.context).editorImageNoDescription
          : viewModel.alt,
      child: imageGestures(
        viewModel.nodeId,
        child: Center(
          // The selection ring is no hit target (a decoration is one).
          child: Stack(
            children: [
              BoxComponent(
                key: componentContext.componentKey,
                opacity: viewModel.opacity,
                child: _WonkyImage(
                  nodeId: viewModel.nodeId,
                  src: viewModel.src,
                  alt: viewModel.alt,
                  title: viewModel.title,
                  services: services,
                  theme: theme,
                  callbacks: callbacks,
                  maxHeight: maxHeight,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: theme.ringColor, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [provider] decoded at most at the display width (Write 04 §36.5, W-05):
/// a 12 MP photo shown 640 px wide is decoded at 640 × the device pixel
/// ratio, not at full resolution. The width is rounded up to 256 px steps
/// so that resizing the window doesn't decode again on every frame; images
/// narrower than that are decoded as they are (never upscaled). The shown
/// size doesn't change: the decoded image is still at least as wide as the
/// space it is fitted into.
ImageProvider atDisplaySize(
  ImageProvider provider,
  double width,
  double devicePixelRatio,
) {
  if (!width.isFinite || width <= 0) return provider;
  final pixels = ((width * devicePixelRatio) / 256).ceil() * 256;
  return ResizeImage(provider, width: pixels);
}

class _WonkyImage extends StatefulWidget {
  const _WonkyImage({
    required this.nodeId,
    required this.src,
    required this.alt,
    required this.title,
    required this.services,
    required this.theme,
    required this.callbacks,
    required this.maxHeight,
  });

  final String nodeId;
  final String src;
  final String alt;
  final String? title;
  final EditorImageServices services;
  final EditorTheme theme;
  final EditorBlockCallbacks callbacks;
  final double? maxHeight;

  @override
  State<_WonkyImage> createState() => _WonkyImageState();
}

class _WonkyImageState extends State<_WonkyImage> {
  ImageProvider? _provider;
  bool _resolving = true;
  bool _broken = false;
  late ValueListenable<ImageUploadStatus?> _upload;

  @override
  void initState() {
    super.initState();
    _upload = widget.services.uploadStatus(widget.src);
    _resolve();
  }

  @override
  void didUpdateWidget(_WonkyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src || oldWidget.services != widget.services) {
      _upload = widget.services.uploadStatus(widget.src);
      _broken = false;
      _untrackSize();
      _resolve();
    }
  }

  @override
  void dispose() {
    _untrackSize();
    super.dispose();
  }

  ImageProvider? _trackedProvider;
  ImageStream? _sizeStream;
  ImageStreamListener? _sizeListener;

  /// Records the natural size of [provider]'s image in [ImageSizeCache] once
  /// it is decoded, for the placeholder size of later loads (§17.3).
  void _trackSize(BuildContext context, ImageProvider? provider) {
    if (provider == _trackedProvider) return;
    _untrackSize();
    _trackedProvider = provider;
    if (provider == null) return;
    final src = widget.src;
    final listener = ImageStreamListener(
      (info, _) {
        ImageSizeCache.instance[src] = Size(
          info.image.width / info.scale,
          info.image.height / info.scale,
        );
        info.dispose();
      },
      // The Image widget reports errors (errorBuilder).
      onError: (_, _) {},
    );
    _sizeStream = provider.resolve(createLocalImageConfiguration(context))
      ..addListener(listener);
    _sizeListener = listener;
  }

  void _untrackSize() {
    final listener = _sizeListener;
    if (listener != null) _sizeStream?.removeListener(listener);
    _sizeStream = null;
    _sizeListener = null;
    _trackedProvider = null;
  }

  /// The loading placeholder's size: the cached natural size if this image
  /// was loaded before, else 16:9 at the available width; both capped like
  /// the image.
  Size _loadingSize(double maxWidth) => ImageSizeCache.fit(
    ImageSizeCache.instance[widget.src] ?? Size(maxWidth, maxWidth * 9 / 16),
    maxWidth,
    widget.maxHeight,
  );

  Future<void> _resolve() async {
    setState(() => _resolving = true);
    final src = widget.src;
    ImageProvider? provider;
    try {
      provider = await widget.services.resolve(src);
    } catch (_) {
      provider = null;
    }
    if (!mounted || widget.src != src) return;
    setState(() {
      _provider = provider;
      _resolving = false;
    });
  }

  void _retry() {
    widget.services.retry(widget.src);
    setState(() => _broken = false);
    _resolve();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640.0;
        return ValueListenableBuilder<ImageUploadStatus?>(
          valueListenable: _upload,
          builder: (context, upload, _) {
            final source = upload?.localPreview ?? _provider;
            final provider = source == null
                ? null
                : atDisplaySize(
                    source,
                    maxWidth,
                    MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
                  );
            _trackSize(context, provider);
            final maxHeight = widget.maxHeight;
            Widget content;
            if (_broken ||
                (provider == null && !_resolving && upload == null)) {
              content = _placeholder(
                maxWidth,
                icon: Icons.broken_image_outlined,
                label: widget.alt.isEmpty
                    ? writeL10n(context).editorImageUnavailable
                    : widget.alt,
                retry: true,
              );
            } else if (provider == null) {
              content = _placeholder(
                maxWidth,
                size: _loadingSize(maxWidth),
                icon: Icons.image_outlined,
                label: upload?.phase == ImageUploadPhase.pending
                    ? (upload?.uploaderName == null
                          ? writeL10n(context).editorImageWaitingForUpload
                          : writeL10n(context).editorImageWaitingForUploadFrom(
                              upload!.uploaderName!,
                            ))
                    : null,
              );
            } else {
              content = ConstrainedBox(
                // Natural size, scaled down (aspect ratio kept) to the
                // content width and, in Pages mode, the page content height.
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight ?? double.infinity,
                ),
                // No hit target: a click reaches the editor, which selects
                // the image.
                child: IgnorePointer(
                  child: Image(
                    image: provider,
                    fit: BoxFit.contain,
                    semanticLabel: widget.alt,
                    errorBuilder: (context, error, stack) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_broken) setState(() => _broken = true);
                      });
                      return _placeholder(
                        maxWidth,
                        icon: Icons.broken_image_outlined,
                        label: widget.alt,
                        retry: true,
                      );
                    },
                    frameBuilder: (context, child, frame, sync) =>
                        frame == null && !sync
                        ? _placeholder(maxWidth, size: _loadingSize(maxWidth))
                        : child,
                  ),
                ),
              );
            }
            final title = widget.title;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (title != null && title.isNotEmpty)
                  // The tooltip still sees the pointer; the click goes on
                  // to the editor.
                  _HitTransparent(
                    child: Tooltip(message: title, child: content),
                  )
                else
                  content,
                if (upload != null &&
                    upload.phase == ImageUploadPhase.uploading)
                  Positioned.fill(
                    child: _UploadOverlay(
                      progress: upload.progress,
                      onCancel: () => widget.services.cancel(widget.src),
                    ),
                  ),
                if (upload != null &&
                    (upload.phase == ImageUploadPhase.failed ||
                        upload.phase == ImageUploadPhase.outOfStorage))
                  Positioned.fill(
                    child: _FailedOverlay(
                      key: ValueKey<String>(
                        upload.phase == ImageUploadPhase.outOfStorage
                            ? WonkyEditorKeys.imageOutOfStorage
                            : WonkyEditorKeys.imageUploadFailed,
                      ),
                      outOfStorage:
                          upload.phase == ImageUploadPhase.outOfStorage,
                      onRetry: _retry,
                      onRemove: widget.callbacks.onRemoveImage == null
                          ? null
                          : () =>
                                widget.callbacks.onRemoveImage!(widget.nodeId),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _placeholder(
    double width, {
    Size? size,
    IconData? icon,
    String? label,
    bool retry = false,
  }) {
    final theme = widget.theme;
    final box =
        size ??
        ImageSizeCache.fit(
          Size(width, width * 9 / 16),
          width,
          widget.maxHeight,
        );
    // Only Retry is a hit target: a click elsewhere reaches the editor.
    return SizedBox(
      width: box.width,
      height: box.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.mutedColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    IgnorePointer(
                      child: Icon(icon, color: theme.mutedColor, size: 32),
                    ),
                  if (label != null)
                    IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: theme.mutedColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (retry)
                    TextButton(
                      key: const ValueKey(WonkyEditorKeys.imageRetry),
                      onPressed: _retry,
                      child: Text(writeL10n(context).imageRetry),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadOverlay extends StatelessWidget {
  const _UploadOverlay({required this.progress, required this.onCancel});

  final double? progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x55000000),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress,
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${(progress! * 100).round()} %',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            IconButton(
              tooltip: writeL10n(context).editorCancelUpload,
              onPressed: onCancel,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red overlay of an image whose upload failed ("Upload failed") or was
/// refused on quota ("Not uploaded — out of storage", Drive 03 §6.3), with
/// *Retry* and *Remove*.
class _FailedOverlay extends StatelessWidget {
  const _FailedOverlay({
    super.key,
    required this.onRetry,
    this.onRemove,
    this.outOfStorage = false,
  });

  final VoidCallback onRetry;
  final VoidCallback? onRemove;
  final bool outOfStorage;

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    return ColoredBox(
      color: const Color(0x99b91c1c),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  outOfStorage
                      ? l.imageNotUploadedOutOfStorage
                      : l.editorUploadFailed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    key: const ValueKey(WonkyEditorKeys.imageUploadRetry),
                    onPressed: onRetry,
                    child: Text(
                      l.imageRetry,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (onRemove != null)
                    TextButton(
                      key: const ValueKey(WonkyEditorKeys.imageUploadRemove),
                      onPressed: onRemove,
                      child: Text(
                        l.imageRemove,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tables (Write 04 §18.2).

/// A legacy `table` embed (super_editor's Markdown table component with the
/// block-selection ring), read-only until the server upgrades it to cell
/// lines (Write 12 §1.5).
class WonkyTableComponentBuilder implements ComponentBuilder {
  const WonkyTableComponentBuilder({required this.theme});

  final EditorTheme theme;
  static const _inner = MarkdownTableComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => node is TableBlockNode ? _inner.createViewModel(document, node) : null;

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! MarkdownTableViewModel) return null;
    final table = _inner.createComponent(componentContext, viewModel);
    if (table == null) return null;
    final selection = viewModel.selection?.nodeSelection;
    final isSelected =
        selection is UpstreamDownstreamNodeSelection && !selection.isCollapsed;
    final rows = viewModel.cells.length;
    final columns = rows == 0 ? 0 : viewModel.cells.first.length;
    return Semantics(
      label: writeL10n(
        componentContext.context,
      ).editorTableLabel(columns, rows),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: theme.ringColor, width: 2)
              : null,
        ),
        child: table,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Code blocks and quotes (Write 04 §14, §15).

/// The space above and below each quote line (px at 100 %), painted over by
/// the quote bar.
const quoteLineSpacing = 2.0;

/// A part of a quote (a quote line, or a list or task item inside a quote,
/// Write 04 §14): [child] with the quote bar in the stylesheet's quote
/// indent left of it, and [spacing] (px at 100 %) above and below inside
/// the bar, so the bars of the quote's parts touch.
Widget quoteBar(
  BuildContext context, {
  required EditorTheme theme,
  required double zoom,
  required double spacing,
  required Widget child,
}) => Semantics(
  label: writeL10n(context).editorQuoteLabel,
  child: CustomPaint(
    painter: _QuoteBarPainter(
      color: theme.quoteBarColor,
      width: theme.quoteBarWidth * zoom,
      // The stylesheet indents quotes by bar width + 12 px; the bar sits in
      // that indent, left of the text.
      gap: 12 * zoom,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: spacing * zoom),
      child: child,
    ),
  ),
);

/// super_editor's list items; inside a quote with the quote bar.
class WonkyListItemComponentBuilder implements ComponentBuilder {
  const WonkyListItemComponentBuilder({
    required this.document,
    required this.theme,
    required this.zoom,
  });

  final Document document;
  final EditorTheme theme;
  final double zoom;
  static const _inner = ListItemComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => _inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    final component = _inner.createComponent(componentContext, viewModel);
    if (component == null ||
        !isQuotedListNode(document.getNodeById(viewModel.nodeId))) {
      return component;
    }
    return quoteBar(
      componentContext.context,
      theme: theme,
      zoom: zoom,
      spacing: theme.listItemSpacing,
      child: component,
    );
  }
}

/// Paragraph components with Wonky chrome: code blocks get a language chip
/// and a copy button; quote lines get a continuous left bar.
class WonkyParagraphComponentBuilder implements ComponentBuilder {
  const WonkyParagraphComponentBuilder({
    required this.document,
    required this.theme,
    required this.zoom,
    this.callbacks = const EditorBlockCallbacks(),
    this.editable = true,
  });

  final Document document;
  final EditorTheme theme;
  final double zoom;
  final EditorBlockCallbacks callbacks;
  final bool editable;
  static const _inner = ParagraphComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! ParagraphNode) return null;
    return _inner.createViewModel(document, node);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! ParagraphComponentViewModel) return null;
    final blockType = viewModel.blockType;
    // super_editor adds the block type to the attributions of every span it
    // styles. For code blocks that is `codeAttribution`, which the inline
    // styler renders as inline code (pill background, smaller size, one
    // color over the syntax colors): the block's look comes from the
    // stylesheet's code rule and the box instead.
    final component = _inner.createComponent(
      componentContext,
      blockType == codeAttribution
          ? (viewModel.copy()..blockType = null)
          : viewModel,
    );
    if (component == null) return null;
    if (blockType == blockquoteAttribution) {
      return quoteBar(
        componentContext.context,
        theme: theme,
        zoom: zoom,
        spacing: quoteLineSpacing,
        child: component,
      );
    }
    if (blockType == codeAttribution) {
      return EditorNodeWatcher(
        document: document,
        nodeId: viewModel.nodeId,
        builder: (_) => _CodeBlockChrome(
          nodeId: viewModel.nodeId,
          node: document.getNodeById(viewModel.nodeId),
          theme: theme,
          zoom: zoom,
          callbacks: callbacks,
          editable: editable,
          child: component,
        ),
      );
    }
    final level = headingLevelOf(blockType);
    if (level != null) {
      return Semantics(
        header: true,
        headingLevel: level,
        // The step changes no view model.
        child: EditorNodeWatcher(
          document: document,
          nodeId: viewModel.nodeId,
          builder: (_) {
            final step = level == 2 || level == 3
                ? stepOf(document.getNodeById(viewModel.nodeId))
                : null;
            return step == null
                ? component
                : _StepHeading(
                    nodeId: viewModel.nodeId,
                    step: step,
                    fontSize: (theme.headings[level - 1].fontSize ?? 20) * zoom,
                    theme: theme,
                    onTap: editable ? callbacks.onStepTap : null,
                    child: component,
                  );
          },
        ),
      );
    }
    return component;
  }
}

/// A numbered heading (Write 11 §7.2): the step number in a badge before
/// the heading text; tapping it edits the number.
class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.nodeId,
    required this.step,
    required this.fontSize,
    required this.theme,
    required this.onTap,
    required this.child,
  });

  final String nodeId;
  final int step;
  final double fontSize;
  final EditorTheme theme;
  final void Function(String nodeId, Rect globalRect)? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = theme.wonky;
    final size = fontSize * style.stepSizeRatio;
    Widget badge = Container(
      key: ValueKey('write.editor.step.$nodeId'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.stepBackground,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$step',
        style: TextStyle(
          fontSize: size * (step >= 100 ? 0.4 : 0.55),
          fontWeight: FontWeight.w700,
          color: style.stepColor,
          height: 1,
        ),
      ),
    );
    if (onTap != null) {
      badge = Tooltip(
        message: writeL10n(context).editorStepNumber,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final box = context.findRenderObject() as RenderBox?;
              onTap!(
                nodeId,
                box == null
                    ? Rect.zero
                    : box.localToGlobal(Offset.zero) & box.size,
              );
            },
            child: badge,
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        badge,
        SizedBox(width: fontSize * 0.45),
        Expanded(child: child),
      ],
    );
  }
}

class _QuoteBarPainter extends CustomPainter {
  _QuoteBarPainter({
    required this.color,
    required this.width,
    required this.gap,
  });

  final Color color;
  final double width;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(-(width + gap), 0, width, size.height),
      Paint()..color = color,
    );
  }

  /// The bar is not a hit target. A [CustomPaint] whose painter does not
  /// answer counts as hit, which made every quote line absorb taps and
  /// clicks before the interactor below the document layer saw them: quote
  /// text could not be clicked, selected or edited (T-19).
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_QuoteBarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.gap != gap;
}

class _CodeBlockChrome extends StatelessWidget {
  const _CodeBlockChrome({
    required this.nodeId,
    required this.node,
    required this.theme,
    required this.zoom,
    required this.callbacks,
    required this.editable,
    required this.child,
  });

  final String nodeId;
  final DocumentNode? node;
  final EditorTheme theme;
  final double zoom;
  final EditorBlockCallbacks callbacks;
  final bool editable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final node = this.node;
    final language = node == null ? '' : codeLanguageOf(node);
    final label = CodeLanguages.displayName(language);
    return Semantics(
      label: writeL10n(context).editorCodeBlockLabel(label),
      child: EditorHoverChrome(
        chrome: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (chipContext) => EditorChromeButton(
                key: ValueKey('${WonkyEditorKeys.codeLanguageChip}.$nodeId'),
                label: label,
                tooltip: writeL10n(context).editorCodeLanguage,
                onTap: !editable || callbacks.onCodeLanguageTap == null
                    ? null
                    : (rect) => callbacks.onCodeLanguageTap!(nodeId, rect),
              ),
            ),
            const SizedBox(width: 4),
            EditorChromeButton(
              key: ValueKey('${WonkyEditorKeys.codeCopy}.$nodeId'),
              icon: Icons.copy_outlined,
              tooltip: writeL10n(context).editorCopyCode,
              onTap: (_) {
                if (callbacks.onCopyCode != null) {
                  callbacks.onCopyCode!(nodeId);
                } else if (node is TextNode) {
                  unawaited(
                    Clipboard.setData(
                      ClipboardData(text: node.text.toPlainText()),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        child: _box(child),
      ),
    );
  }

  /// The whole block as one box: background, rounded corners, border and
  /// inner padding around the paragraph component. The padding is outside
  /// the component's render box, so super_editor's hit-testing, caret and
  /// selection (all relative to that box) stay aligned with the text. The
  /// box ignores pointers: a hit-testable decoration would pull the
  /// surrounding content into the hit path and its gesture detectors would
  /// win taps meant for the editor's interactor.
  Widget _box(Widget component) {
    final padding = theme.codeBlockPadding * zoom;
    final border = theme.codeBlockBorder;
    return Stack(
      key: ValueKey('${WonkyEditorKeys.codeBlock}.$nodeId'),
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.codeBlockBackground,
                borderRadius: BorderRadius.circular(
                  theme.codeBlockRadius * zoom,
                ),
                border: border == BorderSide.none
                    ? null
                    : Border.fromBorderSide(
                        border.copyWith(width: border.width * zoom),
                      ),
              ),
            ),
          ),
        ),
        Padding(
          padding: border == BorderSide.none
              ? padding
              : padding + EdgeInsets.all(border.width * zoom),
          child: component,
        ),
      ],
    );
  }
}

/// The visible content of a block (an image, a video thumbnail) that is not
/// a hit target, so clicks reach the editor's interactor below the
/// document content (which selects the block); a double click calls
/// [onDoubleTap], detected from raw pointer events (no gesture arena).
class EditorBlockContent extends StatefulWidget {
  const EditorBlockContent({
    super.key,
    this.onDoubleTap,
    this.ignoreChild = true,
    required this.child,
  });

  final VoidCallback? onDoubleTap;

  /// `false` when [child] keeps its own buttons (an image's Retry) and
  /// leaves pointers to the editor elsewhere itself.
  final bool ignoreChild;
  final Widget child;

  @override
  State<EditorBlockContent> createState() => _EditorBlockContentState();
}

class _EditorBlockContentState extends State<EditorBlockContent> {
  Duration? _lastDown;
  Offset? _lastPosition;

  void _onDown(PointerDownEvent e) {
    if (e.buttons != kPrimaryButton) return;
    final last = _lastDown;
    final lastPosition = _lastPosition;
    if (last != null &&
        lastPosition != null &&
        e.timeStamp - last <= kDoubleTapTimeout &&
        (e.position - lastPosition).distance <= kDoubleTapSlop) {
      _lastDown = null;
      widget.onDoubleTap?.call();
      return;
    }
    _lastDown = e.timeStamp;
    _lastPosition = e.position;
  }

  @override
  Widget build(BuildContext context) => Listener(
    // Translucent over an ignored child: gets the events, not a hit target.
    behavior: HitTestBehavior.translucent,
    onPointerDown: widget.onDoubleTap == null ? null : _onDown,
    child: widget.ignoreChild
        ? IgnorePointer(child: widget.child)
        : widget.child,
  );
}

/// Rebuilds [builder] when the document changes the node [nodeId]: for
/// what a component reads from its node besides its view model (a numbered
/// heading's step, a code block's language, a container's frames). Such a
/// change alone changes no view model, so the layout would keep showing the
/// old component until something else rebuilt it.
class EditorNodeWatcher extends StatefulWidget {
  const EditorNodeWatcher({
    super.key,
    required this.document,
    required this.nodeId,
    required this.builder,
  });

  final Document document;
  final String nodeId;
  final WidgetBuilder builder;

  @override
  State<EditorNodeWatcher> createState() => _EditorNodeWatcherState();
}

class _EditorNodeWatcherState extends State<EditorNodeWatcher> {
  @override
  void initState() {
    super.initState();
    widget.document.addListener(_onChange);
  }

  @override
  void didUpdateWidget(EditorNodeWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      oldWidget.document.removeListener(_onChange);
      widget.document.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.document.removeListener(_onChange);
    super.dispose();
  }

  void _onChange(DocumentChangeLog log) {
    if (!mounted ||
        !log.changes.any(
          (c) => c is NodeDocumentChange && c.nodeId == widget.nodeId,
        )) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Lets [child] see the pointer (hover, a tooltip) without being a hit
/// target, so the hit test goes on below it (to the editor's interactor).
class _HitTransparent extends SingleChildRenderObjectWidget {
  const _HitTransparent({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTransparent();
}

class _RenderHitTransparent extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    super.hitTest(result, position: position);
    return false;
  }
}

/// Shows [chrome] at the top-right corner while hovered (or [showAlways]);
/// [above] puts it just above the block instead (a block without padding
/// of its own, like a grid, whose first row it would cover).
class EditorHoverChrome extends StatefulWidget {
  const EditorHoverChrome({
    super.key,
    required this.child,
    this.chrome,
    this.showAlways = false,
    this.above = false,
  });

  final Widget child;
  final Widget? chrome;
  final bool showAlways;
  final bool above;

  @override
  State<EditorHoverChrome> createState() => EditorHoverChromeState();
}

class EditorHoverChromeState extends State<EditorHoverChrome> {
  bool _hovered = false;

  /// The pointer is over the chrome (outside the block when [above]).
  bool _chromeHovered = false;
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  bool get _visible => _hovered || _chromeHovered || widget.showAlways;

  @override
  void initState() {
    super.initState();
    // Shown all the time, faded out while hidden (no layout jump).
    if (widget.above) _portal.show();
  }

  Widget _fading(Widget chrome) => AnimatedOpacity(
    duration: const Duration(milliseconds: 120),
    opacity: _visible ? 1 : 0,
    child: IgnorePointer(ignoring: !_visible, child: chrome),
  );

  @override
  Widget build(BuildContext context) {
    final chrome = widget.chrome;
    if (chrome == null) return widget.child;
    if (widget.above) {
      return MouseRegion(
        opaque: false,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _portal,
            // In the overlay: outside the block, the chrome still gets taps.
            overlayChildBuilder: (_) => Positioned(
              left: 0,
              top: 0,
              child: CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.bottomRight,
                // Overlaps the block by a pixel: no gap that drops the hover.
                offset: const Offset(0, 1),
                child: MouseRegion(
                  opaque: false,
                  onEnter: (_) => setState(() => _chromeHovered = true),
                  onExit: (_) => setState(() => _chromeHovered = false),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _fading(chrome),
                  ),
                ),
              ),
            ),
            child: widget.child,
          ),
        ),
      );
    }
    return MouseRegion(
      // Not opaque: an opaque region is a hit target in the document content
      // layer, which hides the pointer from the editor's interactor below
      // it, so taps in the block never placed the caret.
      opaque: false,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(top: 4, right: 4, child: _fading(chrome)),
        ],
      ),
    );
  }
}

/// A small button of block chrome (code language, copy, edit table, …).
class EditorChromeButton extends StatelessWidget {
  const EditorChromeButton({
    super.key,
    this.icon,
    this.label,
    required this.tooltip,
    required this.onTap,
  });

  final IconData? icon;
  final String? label;
  final String tooltip;
  final void Function(Rect globalRect)? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = brightness == Brightness.dark
        ? const Color(0xff2b2f36)
        : const Color(0xffffffff);
    final foreground = brightness == Brightness.dark
        ? const Color(0xffe6e8eb)
        : const Color(0xff374151);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        elevation: 1,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap == null
              ? null
              : () {
                  final box = context.findRenderObject() as RenderBox?;
                  final rect = box == null
                      ? Rect.zero
                      : box.localToGlobal(Offset.zero) & box.size;
                  onTap!(rect);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: icon != null
                ? Icon(icon, size: 14, color: foreground)
                : Text(
                    label ?? '',
                    style: TextStyle(fontSize: 12, color: foreground),
                  ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tasks (Write 04 §13.5).

/// super_editor's task component with the checkbox routed through the
/// `write.list.toggleChecked {nodeId}` command (one labelled undo step).
class WonkyTaskComponentBuilder implements ComponentBuilder {
  WonkyTaskComponentBuilder(
    this._editor, {
    required this.onToggle,
    required this.theme,
    this.zoom = 1,
    this.document,
    this.editable = true,
  }) : _inner = TaskComponentBuilder(_editor);

  final Editor _editor;
  final TaskComponentBuilder _inner;
  final void Function(String nodeId) onToggle;
  final bool editable;

  /// For the quote bar of tasks inside a quote.
  final EditorTheme theme;
  final double zoom;

  /// The document shown (a suggestion preview's); the editor's when null.
  final Document? document;

  Editor get editor => _editor;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    final model = _inner.createViewModel(document, node);
    if (model == null) return null;
    model.setComplete = editable ? (_) => onToggle(node.id) : null;
    return model;
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    final component = _inner.createComponent(componentContext, viewModel);
    if (component == null || viewModel is! TaskComponentViewModel) {
      return component;
    }
    final task = Semantics(
      checked: viewModel.isComplete,
      label: writeL10n(componentContext.context).editorCheckboxLabel,
      child: component,
    );
    final shown = document ?? _editor.document;
    if (!isQuotedListNode(shown.getNodeById(viewModel.nodeId))) {
      return task;
    }
    return quoteBar(
      componentContext.context,
      theme: theme,
      zoom: zoom,
      spacing: theme.listItemSpacing,
      child: task,
    );
  }
}

// -----------------------------------------------------------------------------
// Unknown embeds.

class WonkyEmbedComponentBuilder implements ComponentBuilder {
  const WonkyEmbedComponentBuilder({required this.theme});

  final EditorTheme theme;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! WonkyEmbedNode) return null;
    return _EmbedViewModel(nodeId: node.id, type: node.embedType);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! _EmbedViewModel) return null;
    return BoxComponent(
      key: componentContext.componentKey,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: theme.tableBorderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          writeL10n(
            componentContext.context,
          ).editorUnsupportedContent(viewModel.type),
          style: TextStyle(color: theme.mutedColor),
        ),
      ),
    );
  }
}

class _EmbedViewModel extends SingleColumnLayoutComponentViewModel
    with SelectionAwareViewModelMixin {
  _EmbedViewModel({
    required super.nodeId,
    required this.type,
    super.createdAt,
    super.padding = EdgeInsets.zero,
    super.maxWidth,
  });

  final String type;

  @override
  _EmbedViewModel copy() =>
      _EmbedViewModel(
          nodeId: nodeId,
          type: type,
          padding: padding,
          maxWidth: maxWidth,
        )
        ..selection = selection
        ..selectionColor = selectionColor;
}

// -----------------------------------------------------------------------------
// Horizontal rules.

class WonkyRuleComponentBuilder implements ComponentBuilder {
  const WonkyRuleComponentBuilder({required this.theme});

  final EditorTheme theme;
  static const _inner = HorizontalRuleComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => _inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! HorizontalRuleComponentViewModel) return null;
    final selection = viewModel.selection?.nodeSelection;
    final isSelected =
        selection is UpstreamDownstreamNodeSelection && !selection.isCollapsed;
    return Semantics(
      label: writeL10n(componentContext.context).editorSeparatorLabel,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: theme.ringColor, width: 2)
              : null,
        ),
        child: HorizontalRuleComponent(
          componentKey: componentContext.componentKey,
          color: theme.ruleColor,
          thickness: theme.ruleThickness,
          selection: selection is UpstreamDownstreamNodeSelection
              ? selection
              : null,
          selectionColor: Colors.transparent,
          caretColor: theme.caretColor,
        ),
      ),
    );
  }
}
