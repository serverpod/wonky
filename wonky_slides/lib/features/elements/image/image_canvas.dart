import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_slides_core/model.dart' show ElementKind;

import '../../../l10n/slides_l10n.dart';
import '../../canvas/canvas_interactions.dart';
import '../../editor_screen/deck_editor_controller.dart';
import '../../selection/slide_elements.dart';
import '../../uploads/slides_image_service.dart';
import 'package:wonky_app/platform.dart';
import 'image_rules.dart';

/// Image files dropped on the canvas, waiting for the
/// `slides.insert.image {source: drop}` command that places them (one
/// undo step).
abstract final class ImageDrops {
  static final Expando<List<PickedImage>> _pending = Expando(
    'slidesImageDrops',
  );

  /// Stashes [files] for [ed]'s next drop insert.
  static void put(DeckEditorController ed, List<PickedImage> files) =>
      _pending[ed] = files;

  /// Takes the stashed files of [ed].
  static List<PickedImage> take(DeckEditorController ed) {
    final f = _pending[ed] ?? const <PickedImage>[];
    _pending[ed] = null;
    return f;
  }
}

/// The image layer of the canvas (03 §6.5.1, Drive 03 §6.3): the drop
/// zone for image files from the OS (web; several files insert cascaded,
/// a drop on an empty picture placeholder fills it) and the "Not uploaded
/// — out of storage" badges with *Retry* / *Remove* on images whose upload
/// the server refused.
class ImageCanvasLayer extends CanvasInteraction {
  ImageCanvasLayer(super.c);

  @override
  List<Widget> overlays(BuildContext context) => [
    Positioned.fill(
      child: _ImageLayer(key: const ValueKey('slides.image.layer'), mode: this),
    ),
  ];
}

class _ImageLayer extends StatefulWidget {
  const _ImageLayer({super.key, required this.mode});

  final ImageCanvasLayer mode;

  @override
  State<_ImageLayer> createState() => _ImageLayerState();
}

class _ImageLayerState extends State<_ImageLayer> {
  ExternalDropSource? _drops;
  bool _over = false;

  DeckEditorController get ed => widget.mode.c.editor;

  @override
  void initState() {
    super.initState();
    _drops = ExternalDropSource.platform()
      ..attach(onOver: _onOver, onLeave: _onLeave, onDrop: _onDrop);
  }

  @override
  void dispose() {
    _drops?.detach();
    super.dispose();
  }

  bool _inside(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final local = box.globalToLocal(global);
    return (Offset.zero & box.size).contains(local);
  }

  bool _onOver(Offset global, ExternalDragKind kind) {
    final ok = kind == ExternalDragKind.files && ed.canEdit && _inside(global);
    if (ok != _over && mounted) setState(() => _over = ok);
    return ok;
  }

  void _onLeave() {
    if (_over && mounted) setState(() => _over = false);
  }

  void _onDrop(ExternalDrop drop) {
    _onLeave();
    if (!mounted || !ed.canEdit || !_inside(drop.globalPosition)) return;
    final images = [
      for (final f in drop.files)
        if (SlidesImageRules.byExtension(f.extension) != null ||
            f.mimeType.startsWith('image/'))
          PickedImage(name: f.name, bytes: f.bytes, mimeType: f.mimeType),
    ];
    if (images.isEmpty) {
      if (drop.hasFiles) {
        ed.services.toasts.show(
          slidesL10nOf(ed.services).imageRejectedFormat(drop.files.first.name),
        );
      }
      return;
    }
    final box = context.findRenderObject()! as RenderBox;
    final su = widget.mode.c.viewport.toSlide(
      box.globalToLocal(drop.globalPosition),
    );
    ImageDrops.put(ed, images);
    unawaited(
      ed.invokeCommand(
        'slides.insert.image',
        {'source': 'drop', 'x': su.dx, 'y': su.dy},
        InvocationSource.ui,
        context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = SlidesImageService.of(ed);
    return ListenableBuilder(
      listenable: service.uploadStates,
      builder: (context, _) {
        final theme = ShadTheme.of(context);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_over)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey<String>('slides.image.dropZone'),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: .06),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ..._badges(context, service),
          ],
        );
      },
    );
  }

  /// "Not uploaded — out of storage" on refused images of this slide.
  List<Widget> _badges(BuildContext context, SlidesImageService service) {
    final c = widget.mode.c;
    final els = c.elements;
    if (els == null) return const [];
    final out = <Widget>[];
    final l = slidesL10n(context);
    final theme = ShadTheme.of(context);
    for (final e in els.all) {
      if (e.record.kind != ElementKind.image) continue;
      final src = e.data?['src'];
      final uuid = src is String ? SlidesImageService.fileUuidOf(src) : null;
      if (uuid == null || !service.isOutOfStorage(uuid)) continue;
      final r = c.viewport.rectToViewport(
        SlideElements.frameOf(e, c.scene).bounds,
      );
      out.add(
        Positioned(
          left: r.left,
          top: r.top,
          width: r.width.clamp(140, 1e6),
          child: CanvasChrome(
            child: Container(
              key: ValueKey<String>('slides.image.outOfStorage.${e.id}'),
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.popover,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colorScheme.destructive),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l.imageNotUploadedOutOfStorage,
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.destructive,
                    ),
                  ),
                  ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: () => _run('slides.image.retryUpload', e.id),
                    child: Text(l.imageRetry),
                  ),
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: () =>
                        _run('slides.image.removeNotUploaded', e.id),
                    child: Text(l.imageRemove),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  void _run(String id, String elementId) => unawaited(
    ed.invokeCommand(id, {'id': elementId}, InvocationSource.ui, context),
  );
}
