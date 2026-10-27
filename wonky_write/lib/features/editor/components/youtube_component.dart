import 'package:flutter/material.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show WonkyEmbed, YouTubeEmbed;

import '../../../l10n/write_l10n.dart';
import '../mapping/wonky_embed_node.dart';
import '../mapping/wonky_schema.dart';
import '../styles/editor_theme.dart';
import 'editor_services.dart';
import 'wonky_components.dart';

/// A Wonky Markdown YouTube video (Write 11 §7.2): its thumbnail (16:9) with
/// a play badge and the title below. The editor doesn't play it; Edit… and
/// Open on YouTube are in the hover chrome.
class WonkyYouTubeComponentBuilder implements ComponentBuilder {
  const WonkyYouTubeComponentBuilder({
    required this.services,
    required this.theme,
    required this.zoom,
    this.callbacks = const EditorBlockCallbacks(),
    this.editable = true,
  });

  final EditorImageServices services;
  final EditorTheme theme;
  final double zoom;
  final EditorBlockCallbacks callbacks;
  final bool editable;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! WonkyEmbedNode) return null;
    final video = WonkyEmbed.tryParse(
      node.getMetadataValue(WonkyNodeMetadata.embed),
    );
    if (video is! YouTubeEmbed) return null;
    return YouTubeViewModel(nodeId: node.id, video: video);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! YouTubeViewModel) return null;
    final selection = viewModel.selection?.nodeSelection;
    final isSelected =
        selection is UpstreamDownstreamNodeSelection && !selection.isCollapsed;
    final l = writeL10n(componentContext.context);
    final video = viewModel.video;
    final actions = callbacks.youtube;
    final chrome = actions == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (editable) ...[
                Builder(
                  builder: (c) => EditorChromeButton(
                    key: ValueKey('write.editor.youtube.edit.${video.id}'),
                    icon: LucideIcons.pencil,
                    tooltip: l.cmdYouTubeEdit,
                    onTap: (rect) => actions.onEdit(video.id, rect),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              EditorChromeButton(
                key: ValueKey('write.editor.youtube.open.${video.id}'),
                icon: LucideIcons.externalLink,
                tooltip: l.cmdYouTubeOpen,
                onTap: (_) => actions.onOpen(video.id),
              ),
              if (editable) ...[
                const SizedBox(width: 4),
                EditorChromeButton(
                  key: ValueKey('write.editor.youtube.menu.${video.id}'),
                  icon: LucideIcons.ellipsis,
                  tooltip: l.editorYouTubeMenu,
                  onTap: (rect) => actions.onMenu(video.id, rect),
                ),
              ],
            ],
          );
    final caption = theme.body.copyWith(
      color: theme.mutedColor,
      fontSize: (theme.body.fontSize ?? 14.67) * 0.9,
    );
    return Semantics(
      label: l.editorYouTubeLabel(video.title ?? video.watchUrl),
      child: BoxComponent(
        key: componentContext.componentKey,
        child: EditorHoverChrome(
          showAlways: isSelected,
          above: true,
          chrome: chrome,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6 * zoom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EditorBlockContent(
                  onDoubleTap: editable && actions != null
                      ? () => actions.onEdit(video.id, null)
                      : null,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8 * zoom),
                      border: isSelected
                          ? Border.all(color: theme.ringColor, width: 2)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8 * zoom),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _Thumbnail(
                          key: ValueKey('write.editor.youtube.${video.id}'),
                          services: services,
                          url: video.thumbnailUrl,
                          zoom: zoom,
                        ),
                      ),
                    ),
                  ),
                ),
                if (video.title != null)
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6 * zoom),
                      child: Text(
                        video.title!,
                        style: caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The view model of a YouTube video.
class YouTubeViewModel extends SingleColumnLayoutComponentViewModel
    with SelectionAwareViewModelMixin {
  YouTubeViewModel({
    required super.nodeId,
    required this.video,
    super.createdAt,
    super.padding = EdgeInsets.zero,
    super.maxWidth,
  });

  final YouTubeEmbed video;

  @override
  YouTubeViewModel copy() =>
      YouTubeViewModel(
          nodeId: nodeId,
          video: video,
          padding: padding,
          maxWidth: maxWidth,
        )
        ..selection = selection
        ..selectionColor = selectionColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YouTubeViewModel &&
          other.nodeId == nodeId &&
          other.video == video &&
          other.padding == padding &&
          other.maxWidth == maxWidth &&
          other.selection == selection &&
          other.selectionColor == selectionColor;

  @override
  int get hashCode => Object.hash(nodeId, video, padding, maxWidth, selection);
}

/// The thumbnail behind a play badge; a dark placeholder while it loads or
/// when it can't be loaded.
class _Thumbnail extends StatefulWidget {
  const _Thumbnail({
    super.key,
    required this.services,
    required this.url,
    required this.zoom,
  });

  final EditorImageServices services;
  final String url;
  final double zoom;

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  ImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _resolve();
  }

  Future<void> _resolve() async {
    final url = widget.url;
    ImageProvider? provider;
    try {
      provider = await widget.services.resolve(url);
    } catch (_) {
      provider = null;
    }
    if (!mounted || widget.url != url) return;
    setState(() => _provider = provider);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xff111111)),
        if (provider != null)
          Image(
            image: provider,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        Center(
          child: CustomPaint(
            size: Size(68 * widget.zoom, 48 * widget.zoom),
            painter: const _PlayBadgePainter(),
          ),
        ),
      ],
    );
  }
}

/// A rounded dark badge with a white play triangle.
class _PlayBadgePainter extends CustomPainter {
  const _PlayBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height * 0.28)),
      Paint()..color = const Color(0xd9000000),
    );
    final h = size.height * 0.42;
    final center = rect.center;
    final path = Path()
      ..moveTo(center.dx - h * 0.4, center.dy - h / 2)
      ..lineTo(center.dx + h * 0.55, center.dy)
      ..lineTo(center.dx - h * 0.4, center.dy + h / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xffffffff));
  }

  @override
  bool shouldRepaint(_PlayBadgePainter oldDelegate) => false;
}
