import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/scene.dart' show ShapeLibrary;
import 'package:wonky_slides_core/schema.dart' show ElementCols;
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../features/canvas/canvas_interactions.dart';
import '../features/canvas/slide_canvas_controller.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/elements/element_activation.dart';
import '../features/elements/image/image_adjust_preview.dart';
import '../features/elements/image/crop_mode.dart';
import '../features/elements/image/image_canvas.dart';
import 'package:wonky_app/platform.dart' show ImageClipboard;
import '../features/elements/image/image_dialogs.dart';
import '../features/elements/image/image_geometry.dart';
import '../features/elements/image/image_rules.dart';
import '../features/uploads/slides_image_service.dart';
import '../features/uploads/slides_pending_uploads.dart';
import '../l10n/slides_l10n.dart';
import 'slides_command.dart';

/// The image commands of SL-15 (Slides 03 §6.5, 04 §4.4, §4.5, §6.2,
/// §11.2): insert from upload, Wonky Drive, URL, the clipboard or a drop
/// (offline-first uploads with the quota pre-check), fill picture
/// placeholders, replace, reset, mask, crop (crop mode or a direct write),
/// adjustments, *Download original*, and *Retry* / *Remove* of an upload
/// refused for storage. Every mutating command is one undo step; uploads
/// complete later without another step (03 §15).
List<Command<CommandArgs>> imageCommands(ShellServices s) {
  if (s.client != null) SlidesPendingUploads.install(s);
  CanvasInteractions.register(ImageCropMode.new);
  CanvasInteractions.register(ImageCanvasLayer.new);
  // The live preview of the adjustment sliders (SL-44).
  CanvasInteractions.register(ImageAdjustPreview.new);
  ElementActivations.register(_imageActivation);
  return [
    SlidesCommand(
      'slides.insert.image',
      label: (l) => l.cmdInsertImage,
      icon: LucideIcons.image,
      categoryOf: SlidesCategory.insert,
      mutates: true,
      argsSchema: _sourceSchema,
      enabled: (ed, a) => ed.surfaceId != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) async {
        final got = await _obtain(ctx, ed, a, multiple: true);
        if (got.result != null) return got.result!;
        return _place(ctx, ed, a, got.images);
      },
    ),
    SlidesCommand(
      'slides.image.replace',
      label: (l) => l.cmdImageReplace,
      icon: LucideIcons.imageUp,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: JsonSchema.object(
        properties: {..._sourceProps, 'id': _idSchema},
      ),
      enabled: (ed, a) => _image(ed, a) != null,
      reason: (l, ed) => l.reasonSelectImage,
      run: (ctx, ed, a) async {
        final e = _image(ed, a)!;
        final got = await _obtain(ctx, ed, a, multiple: false);
        if (got.result != null) return got.result!;
        _fill(ctx, ed, e, got.images.single);
        return ok({'elementId': e.id});
      },
    ),
    SlidesCommand(
      'slides.image.reset',
      label: (l) => l.cmdImageReset,
      icon: LucideIcons.rotateCcw,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: JsonSchema.object(properties: {'id': _idSchema}),
      enabled: (ed, a) => _placed(ed, a) != null,
      reason: (l, ed) => l.reasonSelectImage,
      run: (ctx, ed, a) {
        final e = _placed(ed, a)!;
        final data = _ownData(ed, e.id)
          ..remove('crop')
          ..remove('mask')
          ..remove('maskAdjust')
          ..remove('adjust');
        final rec = e.frame;
        final h = ImageGeometry.heightFor(
          _natural(e, 'naturalWidth'),
          _natural(e, 'naturalHeight'),
          rec.width,
        );
        ed.apply(ctx, SetElementData(e.id, jsonEncode(data)));
        if ((h - rec.height).abs() > 0.01) {
          ed.apply(
            ctx,
            UpdateFrames([
              FrameUpdate(
                e.id,
                x: rec.x,
                y: rec.y,
                width: rec.width,
                height: h,
              ),
            ], label: 'Reset image'),
          );
        }
        return ok();
      },
    ),
    SlidesCommand(
      'slides.image.mask',
      label: (l) => l.cmdImageMask,
      icon: LucideIcons.squareDashed,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: JsonSchema.object(
        properties: {
          'id': _idSchema,
          'geometry': JsonSchema.string(
            enumValues: [...ShapeLibrary.keys, 'none'],
            description: 'Shape key of the mask; none removes it.',
          ),
        },
      ),
      enabled: (ed, a) => _placed(ed, a) != null,
      reason: (l, ed) => l.reasonSelectImage,
      run: (ctx, ed, a) async {
        final e = _placed(ed, a)!;
        var geometry = a.string('geometry');
        if (geometry == null) {
          final dc = ctx.dialogContext;
          if (dc == null || ctx.source.isAgent) {
            return const CommandResult.failed('geometry is required');
          }
          geometry = await showImageMaskDialog(
            dc,
            current: e.data?['mask'] as String?,
          );
          if (geometry == null) return const CommandResult.cancelled();
        }
        if (geometry != 'none' && ShapeLibrary.of(geometry) == null) {
          return CommandResult.failed('Unknown shape $geometry');
        }
        final data = _ownData(ed, e.id)
          ..['mask'] = geometry == 'none' ? null : geometry
          ..['maskAdjust'] = null;
        ed.apply(ctx, SetElementData(e.id, jsonEncode(data)));
        return ok();
      },
    ),
    SlidesCommand(
      'slides.image.crop',
      label: (l) => l.cmdImageCrop,
      icon: LucideIcons.crop,
      categoryOf: SlidesCategory.format,
      mutates: true,
      undoLabelOf: (l, a) => l.undoCropImage,
      argsSchema: const JsonSchema.object(
        properties: {
          'id': _idSchema,
          'crop': JsonSchema.object(
            description:
                'Fractions of the natural size removed from each side '
                '(l, t, r, b in 0..1). Without it, the UI enters crop mode.',
            properties: {
              'l': JsonSchema.number(),
              't': JsonSchema.number(),
              'r': JsonSchema.number(),
              'b': JsonSchema.number(),
            },
          ),
          'x': JsonSchema.number(description: 'New frame (su), optional.'),
          'y': JsonSchema.number(),
          'width': JsonSchema.number(),
          'height': JsonSchema.number(),
        },
      ),
      enabled: (ed, a) => _placed(ed, a) != null,
      reason: (l, ed) => l.reasonSelectImage,
      run: (ctx, ed, a) {
        final e = _placed(ed, a)!;
        if (a.values['crop'] == null) {
          if (ctx.source.isAgent) {
            return const CommandResult.failed('crop is required');
          }
          final mode = ImageCropMode.of(ed);
          if (mode == null || !mode.begin(e.id)) {
            return const CommandResult.failed('Crop mode needs the canvas');
          }
          return ok({'cropMode': e.id});
        }
        final crop = ImageCrop.fromJson(a.values['crop']);
        if (crop.visibleWidth < 0.001 || crop.visibleHeight < 0.001) {
          return CommandResult.failed(
            slidesL10nOf(ed.services).errorCropRemovesImage,
          );
        }
        final x = _num(a, 'x'), y = _num(a, 'y');
        final w = _num(a, 'width'), h = _num(a, 'height');
        if (x != null || y != null || w != null || h != null) {
          final rec = e.frame;
          ed.apply(
            ctx,
            UpdateFrames([
              FrameUpdate(
                e.id,
                x: x ?? rec.x,
                y: y ?? rec.y,
                width: w ?? rec.width,
                height: h ?? rec.height,
              ),
            ], label: 'Crop image'),
          );
        }
        final data = _ownData(ed, e.id)..['crop'] = crop.toJson();
        ed.apply(ctx, SetElementData(e.id, jsonEncode(data)));
        return ok();
      },
    ),
    SlidesCommand(
      'slides.image.cropApply',
      label: (l) => l.cmdImageCropApply,
      icon: LucideIcons.check,
      categoryOf: SlidesCategory.format,
      keyScope: SlidesKeyScopes.crop,
      defaultBindings: const [KeyBinding('Enter')],
      showInPalette: false,
      enabled: (ed, a) => ImageCropMode.of(ed)?.active ?? false,
      run: (ctx, ed, a) async {
        await ImageCropMode.of(ed)?.commit(context: ctx.buildContext);
        return ok();
      },
    ),
    SlidesCommand(
      'slides.image.cropCancel',
      label: (l) => l.cmdImageCropCancel,
      icon: LucideIcons.x,
      categoryOf: SlidesCategory.format,
      keyScope: SlidesKeyScopes.crop,
      defaultBindings: const [KeyBinding('Escape')],
      showInPalette: false,
      enabled: (ed, a) => ImageCropMode.of(ed)?.active ?? false,
      run: (ctx, ed, a) {
        ImageCropMode.of(ed)?.cancelCrop();
        ed.canvasFocus.requestFocus();
        return ok();
      },
    ),
    SlidesCommand(
      'slides.image.adjust',
      label: (l) => l.cmdImageAdjust,
      icon: LucideIcons.slidersHorizontal,
      categoryOf: SlidesCategory.format,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'id': _idSchema,
          'brightness': JsonSchema.number(description: '−100…100'),
          'contrast': JsonSchema.number(description: '−100…100'),
          'saturation': JsonSchema.number(description: '−100…100'),
          'temperature': JsonSchema.number(description: '−100…100'),
          'blur': JsonSchema.number(description: '0…40 (su)'),
          'grayscale': JsonSchema.boolean(),
          'sepia': JsonSchema.boolean(),
          'invert': JsonSchema.boolean(),
          'reset': JsonSchema.boolean(description: 'Removes every adjustment.'),
        },
      ),
      enabled: (ed, a) => _placed(ed, a) != null,
      reason: (l, ed) => l.reasonSelectImage,
      run: (ctx, ed, a) {
        final e = _placed(ed, a)!;
        final keys = [
          'brightness',
          'contrast',
          'saturation',
          'temperature',
          'blur',
          'grayscale',
          'sepia',
          'invert',
        ];
        if (!(a.boolean('reset') ?? false) && !keys.any(a.values.containsKey)) {
          // UI without values: the Image section's sliders (04 §13.8).
          ed.openInspector(InspectorTab.format, section: 'image');
          return ok({'opened': 'inspector'});
        }
        final data = _ownData(ed, e.id);
        if (a.boolean('reset') ?? false) {
          data.remove('adjust');
        } else {
          final adj = data['adjust'] is Map
              ? Map<String, Object?>.from(data['adjust'] as Map)
              : <String, Object?>{};
          for (final k in [
            'brightness',
            'contrast',
            'saturation',
            'temperature',
          ]) {
            final v = _num(a, k);
            if (v != null) adj[k] = (v.clamp(-100, 100) / 100);
          }
          final blur = _num(a, 'blur');
          if (blur != null) adj['blur'] = blur.clamp(0, 40).toDouble();
          for (final k in ['grayscale', 'sepia', 'invert']) {
            final v = a.boolean(k);
            if (v != null) adj[k] = v;
          }
          adj.removeWhere((k, v) => v == 0 || v == 0.0 || v == false);
          if (adj.isEmpty) {
            data.remove('adjust');
          } else {
            data['adjust'] = adj;
          }
        }
        ed.apply(ctx, SetElementData(e.id, jsonEncode(data)));
        return ok();
      },
    ),
    SlidesCommand(
      'slides.image.downloadOriginal',
      label: (l) => l.cmdImageDownloadOriginal,
      icon: LucideIcons.download,
      categoryOf: SlidesCategory.format,
      argsSchema: JsonSchema.object(properties: {'id': _idSchema}),
      enabled: (ed, a) =>
          _placed(ed, a) != null &&
          (ed.services.currentItem.value?.canDownload ?? true),
      reason: (l, ed) => _placed(ed, const JsonArgs()) == null
          ? l.reasonSelectImage
          : l.reasonNoDownload,
      run: (ctx, ed, a) async {
        final e = _placed(ed, a)!;
        final src = e.data!['src'] as String;
        final bytes = await SlidesImageService.of(ed).originalBytes(src);
        final l = slidesL10nOf(ed.services);
        if (bytes == null) return CommandResult.failed(l.imageNotAvailable);
        final name = (e.data?['fileName'] as String?) ?? 'image';
        final mime =
            SlidesImageRules.sniff(bytes) ??
            (e.data?['mimeType'] as String?) ??
            'application/octet-stream';
        final saved = await SlidesImageIo.save(
          name,
          bytes,
          mime,
          l.cmdImageDownloadOriginal,
        );
        return saved ? ok({'fileName': name}) : const CommandResult.cancelled();
      },
    ),
    SlidesCommand(
      'slides.image.retryUpload',
      label: (l) => l.cmdImageRetryUpload,
      icon: LucideIcons.refreshCw,
      categoryOf: SlidesCategory.format,
      showInPalette: false,
      argsSchema: JsonSchema.object(properties: {'id': _idSchema}),
      enabled: (ed, a) => _refused(ed, a) != null,
      reason: (l, ed) => l.reasonSelectImage,
      run: (ctx, ed, a) {
        SlidesImageService.of(ed).retryUpload(_refused(ed, a)!.$2);
        return ok();
      },
    ),
    SlidesCommand(
      'slides.image.removeNotUploaded',
      label: (l) => l.cmdImageRemoveNotUploaded,
      icon: LucideIcons.trash2,
      categoryOf: SlidesCategory.format,
      mutates: true,
      showInPalette: false,
      argsSchema: JsonSchema.object(properties: {'id': _idSchema}),
      enabled: (ed, a) => _refused(ed, a) != null,
      reason: (l, ed) => l.reasonSelectImage,
      run: (ctx, ed, a) {
        final (e, uuid) = _refused(ed, a)!;
        ed.apply(ctx, DeleteElements([e.id]));
        SlidesImageService.of(ed).forgetUpload(uuid);
        return ok();
      },
    ),
  ];
}

// ------------------------------------------------------------------ args

const _idSchema = JsonSchema.string(
  description: 'Image element id (default: the selected image).',
);

final _sourceSchema = JsonSchema.object(properties: _sourceProps);

const _sourceProps = <String, JsonSchema>{
  'source': JsonSchema.string(
    enumValues: ['upload', 'drive', 'url', 'clipboard', 'drop'],
    description:
        'upload (file picker), drive (fileItemUuid), url (https), '
        'clipboard, drop (files dropped on the canvas); no source opens '
        'the source dialog.',
  ),
  'url': JsonSchema.string(description: 'https image URL.'),
  'fileItemUuid': JsonSchema.string(
    description: 'A Wonky Drive image file (source drive).',
  ),
  'x': JsonSchema.number(
    description: 'Center of the new image (su); default the slide center.',
  ),
  'y': JsonSchema.number(),
};

double? _num(JsonArgs a, String k) {
  final v = a.values[k];
  return v is num ? v.toDouble() : null;
}

/// The image element of [a] (`id`) or the single selected image.
ResolvedElement? _image(DeckEditorController ed, JsonArgs a) {
  final slide = ed.surfaceId;
  if (slide == null) return null;
  final resolved = ed.resolver.resolve(slide);
  if (resolved == null) return null;
  final id =
      a.string('id') ??
      (ed.selectedElementIds.length == 1 ? ed.selectedElementIds.single : null);
  if (id == null) return null;
  final e = _find(resolved.elements, id);
  return e != null && e.record.kind == ElementKind.image ? e : null;
}

ResolvedElement? _find(List<ResolvedElement> list, String id) {
  for (final e in list) {
    if (e.id == id) return e;
    final c = _find(e.children, id);
    if (c != null) return c;
  }
  return null;
}

/// [_image] with a source (not an empty picture placeholder).
ResolvedElement? _placed(DeckEditorController ed, JsonArgs a) {
  final e = _image(ed, a);
  final src = e?.data?['src'];
  return src is String && src.isNotEmpty ? e : null;
}

/// An image whose upload the server refused for storage, and its file.
(ResolvedElement, String)? _refused(DeckEditorController ed, JsonArgs a) {
  final e = _placed(ed, a);
  if (e == null) return null;
  final uuid = SlidesImageService.fileUuidOf(e.data!['src'] as String);
  if (uuid == null) return null;
  return SlidesImageService.of(ed).isOutOfStorage(uuid) ? (e, uuid) : null;
}

/// Whether [e] is an empty picture placeholder (03 §6.2: "Click to add an
/// image").
bool isEmptyPicture(ResolvedElement e) {
  if (e.record.kind != ElementKind.image) return false;
  final src = e.data?['src'];
  return (src is! String || src.isEmpty) &&
      e.placeholderType == SlidePlaceholderType.picture;
}

double _natural(ResolvedElement e, String k) =>
    (e.data?[k] as num?)?.toDouble() ?? 0;

/// The element's own `dataJson` (not the placeholder chain's).
Map<String, Object?> _ownData(DeckEditorController ed, String id) {
  final raw = ed.model.element(id)?.dataJson;
  if (raw == null) return {'v': 1};
  try {
    final v = jsonDecode(raw);
    return v is Map ? Map<String, Object?>.from(v) : {'v': 1};
  } on FormatException {
    return {'v': 1};
  }
}

// ---------------------------------------------------------------- obtain

/// An image to place: prepared bytes, and the file uuid when it is already
/// on the server (a Drive copy).
typedef _Ready = ({PreparedImage image, String? fileUuid});

typedef _Obtained = ({List<_Ready> images, CommandResult? result});

_Obtained _fail(CommandResult r) => (images: const [], result: r);

/// Gets the images of an insert/replace from the `source` args, the
/// dialogs, the clipboard or a drop; validates and prepares them (03
/// §6.5.1) and runs the quota pre-check for uploads (Drive 03 §7.2: the
/// bytes count against the deck's owner).
Future<_Obtained> _obtain(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a, {
  required bool multiple,
}) async {
  final l = slidesL10nOf(ed.services);
  final agent = ctx.source.isAgent;
  var source = a.string('source');
  if (source == null) {
    final dc = ctx.dialogContext;
    if (dc == null || agent) {
      return _fail(const CommandResult.failed('source is required'));
    }
    source = await showImageSourceDialog(dc, replace: !multiple);
    if (source == null) return _fail(const CommandResult.cancelled());
  }
  final service = SlidesImageService.of(ed);
  final picked = <PickedImage>[];
  try {
    switch (source) {
      case 'upload':
        if (agent) {
          return _fail(
            const CommandResult.failed('upload needs the file picker (UI)'),
          );
        }
        picked.addAll(
          await SlidesImageIo.pick(title: l.imagePickTitle, multiple: multiple),
        );
      case 'clipboard':
        final c = await ImageClipboard.instance.readImage();
        if (c == null) {
          return _fail(CommandResult.failed(l.imageClipboardEmpty));
        }
        picked.add(
          PickedImage(
            name: 'Pasted image.${c.mimeType.split('/').last}',
            bytes: c.bytes,
            mimeType: c.mimeType,
          ),
        );
      case 'drop':
        picked.addAll(ImageDrops.take(ed));
      case 'url':
        var url = a.string('url');
        if (url == null) {
          final dc = ctx.dialogContext;
          if (dc == null || agent) {
            return _fail(const CommandResult.failed('url is required'));
          }
          // ignore: use_build_context_synchronously
          url = await showImageUrlDialog(dc);
          if (url == null) return _fail(const CommandResult.cancelled());
        }
        if (!isImageUrl(url)) {
          return _fail(CommandResult.failed(l.imageUrlInvalid));
        }
        final Uint8List bytes;
        try {
          bytes = await service.fetchRemote(url.trim());
        } catch (e) {
          return _fail(CommandResult.failed(l.imageFetchFailed));
        }
        final uri = Uri.parse(url.trim());
        picked.add(
          PickedImage(
            name: uri.pathSegments.lastOrNull ?? 'image',
            bytes: bytes,
            mimeType: '',
          ),
        );
      case 'drive':
        return await _fromDrive(ctx, ed, a);
      default:
        return _fail(CommandResult.failed('Unknown source $source'));
    }
  } on ImageRejected catch (e) {
    return _fail(CommandResult.failed(_rejected(l, e, '')));
  }
  if (picked.isEmpty) return _fail(const CommandResult.cancelled());
  final ready = <_Ready>[];
  final failures = <String>[];
  for (final p in multiple ? picked : picked.take(1)) {
    try {
      final mime = SlidesImageRules.validate(p.name, p.bytes);
      final prepared = await SlidesImagePrep.prepare(
        PickedImage(name: p.name, bytes: p.bytes, mimeType: mime),
      );
      ready.add((image: prepared, fileUuid: null));
    } on ImageRejected catch (e) {
      failures.add(_rejected(l, e, p.name));
    }
  }
  if (failures.isNotEmpty) ed.services.toasts.error(failures.join('\n'));
  if (ready.isEmpty) {
    return _fail(CommandResult.failed(failures.firstOrNull ?? 'No image'));
  }
  final total = ready.fold<int>(0, (n, r) => n + r.image.image.bytes.length);
  if (!agent &&
      !await ed.services.storageChecks.ensureRoom(
        total,
        reason: QuotaReasons.image,
        item: ed.services.currentItem.value,
      )) {
    return _fail(const CommandResult.cancelled());
  }
  return (images: ready, result: null);
}

String _rejected(SlidesLocalizations l, ImageRejected e, String name) =>
    switch (e.reason) {
      ImageRejectReason.tooLarge => l.imageRejectedTooLarge(name),
      ImageRejectReason.unsupportedFormat => l.imageRejectedFormat(name),
    };

/// *From Wonky Drive*: the server copies the file into the deck (quota of
/// the deck's owner; `file.copyToItem`).
Future<_Obtained> _fromDrive(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a,
) async {
  final l = slidesL10nOf(ed.services);
  final s = ed.services;
  UuidValue? contentRef;
  String name = 'image';
  final itemArg = a.string('fileItemUuid');
  try {
    if (itemArg != null) {
      final item = await s.drive.get(UuidValue.withValidation(itemArg));
      contentRef = item.contentRef;
      name = item.name;
    } else {
      final dc = ctx.dialogContext;
      if (dc == null || ctx.source.isAgent) {
        return _fail(const CommandResult.failed('fileItemUuid is required'));
      }
      final item = await showDriveImagePicker(dc, s);
      if (item == null) return _fail(const CommandResult.cancelled());
      contentRef = item.contentRef;
      name = item.name;
    }
    if (contentRef == null) {
      return _fail(CommandResult.failed(l.imageNotAvailable));
    }
    final (uuid, bytes) = await SlidesImageService.of(
      ed,
    ).copyFromDrive(contentRef);
    final mime = SlidesImageRules.validate(name, bytes);
    final prepared = await SlidesImagePrep.prepare(
      PickedImage(name: name, bytes: bytes, mimeType: mime),
    );
    // A Drive image that had to be converted (SVG, BMP, > 40 MP) is
    // uploaded as converted; else the server copy is used as is.
    final same = identical(prepared.image.bytes, bytes);
    return (
      images: [(image: prepared, fileUuid: same ? uuid : null)],
      result: null,
    );
  } on ImageRejected catch (e) {
    return _fail(CommandResult.failed(_rejected(l, e, name)));
  } catch (e) {
    if (QuotaErrorPresenter.isQuotaExceeded(e)) {
      if (!ctx.source.isAgent) {
        s.quotaErrors.present(e, reason: QuotaReasons.image);
      }
      return _fail(CommandResult.failed(l.imageOutOfStorage));
    }
    return _fail(CommandResult.failed(l.imageFetchFailed));
  }
}

/// The `src` of [r]: its server copy, or a new upload (stored on the
/// device first, 12 §1.1).
String _srcOf(DeckEditorController ed, _Ready r) {
  final uuid =
      r.fileUuid ??
      SlidesImageService.of(ed).startUpload(
        r.image.image.bytes,
        r.image.image.mimeType,
        r.image.image.name,
      );
  return '${SlidesImageService.scheme}$uuid';
}

Map<String, Object?> _imageData(String src, PreparedImage p) => {
  'v': 1,
  'src': src,
  'naturalWidth': p.width,
  'naturalHeight': p.height,
  'fileName': p.image.name,
  'mimeType': p.image.mimeType,
};

/// Places [images] (03 §6.5.1): one image into a selected (or dropped-on)
/// empty picture placeholder fills it; otherwise new image elements at
/// their natural size scaled to 80 % of the slide, centered on the slide
/// or the drop point, several cascaded. One undo step.
CommandResult _place(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a,
  List<_Ready> images,
) {
  final slide = ed.surfaceId;
  if (slide == null) return const CommandResult.failed('No slide');
  final x = _num(a, 'x'), y = _num(a, 'y');
  final target = _placeholderTarget(ed, x, y);
  if (target != null && images.length == 1) {
    _fill(ctx, ed, target, images.single);
    selectionOf(ed).select([target.id]);
    return ok({'elementId': target.id});
  }
  final d = ed.model.deck;
  final sw = d?.width ?? 1920, sh = d?.height ?? 1080;
  final specs = <ElementSpec>[];
  for (final (i, r) in images.indexed) {
    final box = ImageGeometry.place(
      r.image.width.toDouble(),
      r.image.height.toDouble(),
      slideW: sw,
      slideH: sh,
      at: x == null || y == null ? null : (x: x + 24.0 * i, y: y + 24.0 * i),
    );
    final off = x == null ? 24.0 * i : 0.0;
    specs.add(
      ElementSpec(
        kind: ElementKind.image,
        x: box.x + off,
        y: box.y + off,
        width: box.width,
        height: box.height,
        columns: {
          ElementCols.dataJson: jsonEncode(_imageData(_srcOf(ed, r), r.image)),
        },
      ),
    );
  }
  final plan = ed.apply(
    ctx,
    InsertElements(slide, specs, ownerKind: ed.surfaceKind),
  );
  final ids = plan.result['elementIds'];
  ed.armTool(null);
  if (ids is List && ids.isNotEmpty) {
    selectionOf(ed).select(ids.whereType<String>());
    ed.canvasFocus.requestFocus();
  }
  return ok({
    'elementIds': ids is List ? ids : const <Object?>[],
    'elementId': ids is List && ids.isNotEmpty ? ids.first : null,
  });
}

/// The empty picture placeholder to fill: the one at ([x], [y]) for a
/// drop, else the single selected one.
ResolvedElement? _placeholderTarget(
  DeckEditorController ed,
  double? x,
  double? y,
) {
  // Layout and master placeholders are definitions, not filled (SL-28).
  final slide = ed.editsMasters ? null : ed.currentSlideId;
  final resolved = slide == null ? null : ed.resolver.resolve(slide);
  if (resolved == null) return null;
  if (x != null && y != null) {
    final canvas = SlideCanvasController.of(ed);
    final hit = canvas?.pick(Offset(x, y));
    final e = hit == null ? null : _find(resolved.elements, hit.$1);
    return e != null && isEmptyPicture(e) ? e : null;
  }
  final ids = ed.selectedElementIds;
  if (ids.length != 1) return null;
  final e = _find(resolved.elements, ids.single);
  return e != null && isEmptyPicture(e) ? e : null;
}

/// Puts [r] into image [e] keeping its frame (re-fit to cover it, 03
/// §6.5.2), mask, adjustments, builds and match key.
void _fill(
  CommandContext ctx,
  DeckEditorController ed,
  ResolvedElement e,
  _Ready r,
) {
  final f = e.frame;
  final crop = ImageGeometry.cover(
    r.image.width.toDouble(),
    r.image.height.toDouble(),
    f.width,
    f.height,
  );
  ed.apply(
    ctx,
    ReplaceImage(
      e.id,
      src: _srcOf(ed, r),
      naturalWidth: r.image.width,
      naturalHeight: r.image.height,
      fileName: r.image.image.name,
      mimeType: r.image.image.mimeType,
      crop: crop.isNone ? null : crop.toJson(),
    ),
  );
}

// ------------------------------------------------------------ activation

/// Double-click / Enter on an image (03 §3.4): crop mode; on an empty
/// picture placeholder: *Insert image*.
final _imageActivation = ElementActivation(
  applies: (ed, a) => _image(ed, const JsonArgs()) != null,
  run: (ctx, ed, a) async {
    final e = _image(ed, const JsonArgs())!;
    if (isEmptyPicture(e)) {
      return ed.services.dispatcher.invoke(
        'slides.insert.image',
        source: ctx.source,
        context: ctx.buildContext,
      );
    }
    final mode = ImageCropMode.of(ed);
    if (mode == null || !mode.begin(e.id)) {
      return const CommandResult.failed('Nothing to edit');
    }
    return ok({'cropMode': e.id});
  },
);
