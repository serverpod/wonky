import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../../../l10n/write_l10n.dart';

import '../mapping/wonky_embed_node.dart';
import '../mapping/wonky_schema.dart';
import '../model/code_languages.dart';
import '../model/embeds.dart';
import '../styles/editor_theme.dart';
import '../tables/inline_table_editing.dart';
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
    final selection =
        viewModel.selection?.nodeSelection as UpstreamDownstreamNodeSelection?;
    final isSelected = selection != null && !selection.isCollapsed;
    return Semantics(
      image: true,
      label: viewModel.alt.isEmpty
          ? writeL10n(componentContext.context).editorImageNoDescription
          : viewModel.alt,
      child: GestureDetector(
        onTap: editable || callbacks.onImageTap == null
            ? null
            : () => callbacks.onImageTap!(viewModel.nodeId),
        onDoubleTap: !editable || callbacks.onImageDoubleTap == null
            ? null
            : () => callbacks.onImageDoubleTap!(viewModel.nodeId),
        child: Center(
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: theme.ringColor, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: BoxComponent(
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
              );
            }
            final title = widget.title;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (title != null && title.isNotEmpty)
                  Tooltip(message: title, child: content)
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
    return SizedBox(
      width: box.width,
      height: box.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.mutedColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, color: theme.mutedColor, size: 32),
                if (label != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(color: theme.mutedColor, fontSize: 13),
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

/// Wraps super_editor's Markdown table component with an "Edit table" button
/// and the block-selection ring. With [inlineEditing] (patch SE-4) cells are
/// edited in place; otherwise double-click opens the table editor.
class WonkyTableComponentBuilder implements ComponentBuilder {
  const WonkyTableComponentBuilder({
    required this.theme,
    this.callbacks = const EditorBlockCallbacks(),
    this.editable = true,
    this.inlineEditing,
  });

  final EditorTheme theme;
  final EditorBlockCallbacks callbacks;
  final bool editable;

  /// In-place cell editing (Write 04 §18.4).
  final InlineTableEditing? inlineEditing;
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
    var tableModel = viewModel;
    final inline = editable ? inlineEditing : null;
    // Selected tables show the ring, not a translucent fill over the cells
    // (which would also cover the cell being edited). On a copy: the
    // presenter keeps `viewModel` to compare with the next pass, and a
    // mutated one never equals it, so every table would be rebuilt on every
    // keystroke (W-12).
    if (inline != null) {
      tableModel = tableModel.copy() as MarkdownTableViewModel
        ..selectionColor = const Color(0x00000000);
    }
    final table = inline == null
        ? _inner.createComponent(componentContext, tableModel)
        : MarkdownTableComponent(
            componentKey: componentContext.componentKey,
            viewModel: tableModel,
            cellBuilder: inlineTableCellBuilder(inline, theme),
          );
    if (table == null) return null;
    final selection = tableModel.selection?.nodeSelection;
    final isSelected =
        selection is UpstreamDownstreamNodeSelection && !selection.isCollapsed;
    final rows = tableModel.cells.length;
    final columns = rows == 0 ? 0 : tableModel.cells.first.length;
    return Semantics(
      label: writeL10n(
        componentContext.context,
      ).editorTableLabel(columns, rows),
      child: GestureDetector(
        onDoubleTap:
            !editable || inline != null || callbacks.onEditTable == null
            ? null
            : () => callbacks.onEditTable!(viewModel.nodeId),
        child: _HoverChrome(
          showAlways: isSelected,
          chrome: !editable || callbacks.onEditTable == null
              ? null
              : _ChromeButton(
                  key: ValueKey(
                    '${WonkyEditorKeys.tableEdit}.${viewModel.nodeId}',
                  ),
                  icon: Icons.edit_outlined,
                  tooltip: writeL10n(componentContext.context).editorEditTable,
                  onTap: (_) => callbacks.onEditTable!(viewModel.nodeId),
                ),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: theme.ringColor, width: 2)
                  : null,
            ),
            child: table,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Code blocks and quotes (Write 04 §14, §15).

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
      return Semantics(
        label: writeL10n(componentContext.context).editorQuoteLabel,
        child: CustomPaint(
          painter: _QuoteBarPainter(
            color: theme.quoteBarColor,
            width: theme.quoteBarWidth * zoom,
            // The stylesheet indents quotes by bar width + 12 px; the bar
            // sits in that indent, left of the text.
            gap: 12 * zoom,
          ),
          child: component,
        ),
      );
    }
    if (blockType == codeAttribution) {
      final node = document.getNodeById(viewModel.nodeId);
      return _CodeBlockChrome(
        nodeId: viewModel.nodeId,
        node: node,
        theme: theme,
        zoom: zoom,
        callbacks: callbacks,
        editable: editable,
        child: component,
      );
    }
    final level = headingLevelOf(blockType);
    if (level != null) {
      return Semantics(header: true, headingLevel: level, child: component);
    }
    return component;
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
      child: _HoverChrome(
        chrome: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (chipContext) => _ChromeButton(
                key: ValueKey('${WonkyEditorKeys.codeLanguageChip}.$nodeId'),
                label: label,
                tooltip: writeL10n(context).editorCodeLanguage,
                onTap: !editable || callbacks.onCodeLanguageTap == null
                    ? null
                    : (rect) => callbacks.onCodeLanguageTap!(nodeId, rect),
              ),
            ),
            const SizedBox(width: 4),
            _ChromeButton(
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

/// Shows [chrome] at the top-right corner while hovered (or [showAlways]).
class _HoverChrome extends StatefulWidget {
  const _HoverChrome({
    required this.child,
    this.chrome,
    this.showAlways = false,
  });

  final Widget child;
  final Widget? chrome;
  final bool showAlways;

  @override
  State<_HoverChrome> createState() => _HoverChromeState();
}

class _HoverChromeState extends State<_HoverChrome> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final chrome = widget.chrome;
    if (chrome == null) return widget.child;
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
          Positioned(
            top: 4,
            right: 4,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _hovered || widget.showAlways ? 1 : 0,
              child: IgnorePointer(
                ignoring: !(_hovered || widget.showAlways),
                child: chrome,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
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
    this.editable = true,
  }) : _inner = TaskComponentBuilder(_editor);

  final Editor _editor;
  final TaskComponentBuilder _inner;
  final void Function(String nodeId) onToggle;
  final bool editable;

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
    return Semantics(
      checked: viewModel.isComplete,
      label: writeL10n(componentContext.context).editorCheckboxLabel,
      child: component,
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
