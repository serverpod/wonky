import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show CellPos, FRich, ImageValue;
import 'package:wonky_sheets_core/model.dart';

import '../features/history/change_labels.dart';
import '../features/images/image_blob_cache.dart';
import 'package:wonky_app/platform.dart' show ImageClipboard;
import '../features/images/image_dialogs.dart';
import '../features/images/image_io.dart';
import '../features/images/image_prepare.dart';
import '../features/images/image_service.dart';
import '../features/objects/object_ops.dart';
import '../features/objects/objects_controller.dart';
import '../features/sheet_editor/sheet_editor_controller.dart';
import 'sheets_command.dart';

SheetsText _cat = (l) => l.categoryImages;

ObjectsController _objs(SheetEditorController ed) => ObjectsController.of(ed);

EmbeddedObjectRecord? _image(SheetEditorController ed, JsonArgs a) {
  final o = ObjectOps.target(ed, a.values);
  return o?.kind == EmbeddedObjectKind.image ? o : null;
}

const _sourceProps = {
  'source': JsonSchema.string(
    enumValues: ['upload', 'url', 'clipboard'],
    description:
        'upload (file picker), url or clipboard (an image on the system '
        'clipboard); no source opens the dialog.',
  ),
  'url': JsonSchema.string(description: 'https image URL (source url).'),
};

/// A picked/fetched image (prepared for upload), or the failure/cancel
/// result.
typedef _Obtained = ({
  PreparedImage? image,
  String? url,
  CommandResult? result,
});

/// Prepares [img] (SVG rasterizing, downscaling, 08 §10.1) as an
/// [_Obtained], after the quota pre-check (Drive 03 §7.2: the image counts
/// against the spreadsheet's owner; the *Out of storage* dialog explains a
/// refusal).
Future<_Obtained> _prepared(
  SheetEditorController ed,
  PickedImage img, {
  String? url,
  bool interactive = true,
}) async {
  final l = ed.l10n;
  try {
    final p = await SheetsImagePrep.prepare(img);
    final s = ed.services;
    // Agents (MCP, AI) get the server's `quota_exceeded` instead of a dialog.
    if (interactive &&
        !await s.storageChecks.ensureRoom(
          p.image.bytes.length,
          reason: QuotaReasons.image,
          item: s.currentItem.value,
        )) {
      return (image: null, url: null, result: const CommandResult.cancelled());
    }
    return (image: p, url: url, result: null);
  } on ImageRejected catch (e) {
    return (
      image: null,
      url: null,
      result: CommandResult.failed(_reject(l, e)),
    );
  }
}

/// The image on the system clipboard as a picked image (null when there is
/// none). Throws [ImageRejected].
Future<PickedImage?> clipboardImage() async {
  final c = await ImageClipboard.instance.readImage();
  if (c == null) return null;
  final name = 'Pasted image.${c.mimeType.split('/').last}';
  final mime = SheetsImageRules.validate(name, c.bytes);
  return PickedImage(name: name, bytes: c.bytes, mimeType: mime);
}

/// Gets the image of an insert/replace command: from `source` args, or the
/// insert dialog. With [urlOnly] (in-cell inserts by URL) the URL is
/// returned without downloading.
Future<_Obtained> _obtain(
  CommandContext ctx,
  SheetEditorController ed,
  JsonArgs a, {
  required bool inCell,
  bool urlOnly = false,
}) async {
  final l = ed.l10n;
  var source = a.string('source');
  var url = a.string('url');
  if (source == null) {
    final c = ctx.dialogContext;
    if (c == null) {
      return (
        image: null,
        url: null,
        result: const CommandResult.failed('source is required'),
      );
    }
    final choice = await showInsertImageDialog(c, inCell: inCell);
    switch (choice) {
      case null:
        return (
          image: null,
          url: null,
          result: const CommandResult.cancelled(),
        );
      case UploadImageChoice():
        source = 'upload';
      case ClipboardImageChoice():
        source = 'clipboard';
      case UrlImageChoice(url: final u):
        source = 'url';
        url = u;
    }
  }
  if (source == 'url') {
    final u = url?.trim() ?? '';
    final uri = Uri.tryParse(u);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return (
        image: null,
        url: null,
        result: CommandResult.failed(l.dialogImageUrlInvalid),
      );
    }
    if (urlOnly) return (image: null, url: u, result: null);
    try {
      final bytes = await SheetsImageService.of(ed).fetchRemote(u);
      final mime = SheetsImageRules.validate(
        uri.pathSegments.lastOrNull ?? '',
        bytes,
      );
      final name = uri.pathSegments.lastOrNull ?? 'image';
      return await _prepared(
        ed,
        PickedImage(name: name, bytes: bytes, mimeType: mime),
        url: u,
        interactive: !ctx.source.isAgent,
      );
    } on ImageRejected catch (e) {
      return (
        image: null,
        url: null,
        result: CommandResult.failed(_reject(l, e)),
      );
    } catch (e) {
      return (
        image: null,
        url: null,
        result: CommandResult.failed(l.imageFetchFailed),
      );
    }
  }
  try {
    if (source == 'clipboard') {
      final img = await clipboardImage();
      if (img == null) {
        return (
          image: null,
          url: null,
          result: CommandResult.failed(l.imageClipboardEmpty),
        );
      }
      return await _prepared(ed, img, interactive: !ctx.source.isAgent);
    }
    final img = await SheetsFileIo.pickImage(l);
    if (img == null) {
      return (image: null, url: null, result: const CommandResult.cancelled());
    }
    return await _prepared(ed, img, interactive: !ctx.source.isAgent);
  } on ImageRejected catch (e) {
    return (
      image: null,
      url: null,
      result: CommandResult.failed(_reject(l, e)),
    );
  }
}

String _reject(SheetsLocalizations l, ImageRejected e) => switch (e.reason) {
  ImageRejectReason.tooLarge => l.imageRejectedTooLarge,
  ImageRejectReason.unsupportedFormat => l.imageRejectedFormat,
};

/// `=IMAGE("…")` input for a cell (08 §10.2).
String imageFormula(String url, {int? mode}) {
  final quoted = url.replaceAll('"', '""');
  return mode == null || mode == 1
      ? '=IMAGE("$quoted")'
      : '=IMAGE("$quoted", $mode)';
}

/// Inserts [img] over cells with its top-left at ([row], [col]) of the
/// active sheet (08 §10.1: natural size scaled to fit 600 × 400 px, aspect
/// locked), starts its upload and selects it. Returns the object id.
String insertImageOverCells(
  CommandContext ctx,
  SheetEditorController ed,
  PreparedImage img, {
  required int row,
  required int col,
  String? sourceUrl,
}) {
  final sheet = ed.activeSheet!;
  final uuid = SheetsImageService.of(ed).startUpload(img.image);
  final anchor = ObjectPlacement.imageAnchor(
    row: row,
    col: col,
    naturalWidth: img.size.width,
    naturalHeight: img.size.height,
    rows: sheet.rows,
    columns: sheet.columns,
  );
  final spec = ImageSpec(
    fileUuid: uuid,
    mime: img.image.mimeType,
    naturalWidth: img.size.width.round(),
    naturalHeight: img.size.height.round(),
    sourceUrl: sourceUrl,
  );
  final plan = ed.apply(
    ctx,
    AddObject(
      sheet.id,
      EmbeddedObjectKind.image,
      anchorJson: anchor.encode(),
      specJson: spec.encode(),
    ),
  );
  final id = plan.result['objectId']! as String;
  _objs(ed).select(id);
  return id;
}

String? _fileOf(SheetEditorController ed, String objectId) {
  final o = _objs(ed).record(objectId);
  return o == null ? null : ImageSpec.fromJson(o.specJson).fileUuid;
}

/// Pastes an image from the system clipboard over cells at the active cell
/// (08 §9.5: Mod+V in the grid with an image and no text on the
/// clipboard). Null when the clipboard holds no such image (the cell paste
/// goes on).
Future<CommandResult?> pasteClipboardImage(
  CommandContext ctx,
  SheetEditorController ed,
) async {
  if (!ImageClipboard.instance.supported) return null;
  final c = await ImageClipboard.instance.readImage();
  if (c == null || c.hasText) return null;
  final l = ed.l10n;
  final PickedImage picked;
  try {
    final name = 'Pasted image.${c.mimeType.split('/').last}';
    picked = PickedImage(
      name: name,
      bytes: c.bytes,
      mimeType: SheetsImageRules.validate(name, c.bytes),
    );
  } on ImageRejected catch (e) {
    return CommandResult.failed(_reject(l, e));
  }
  final got = await _prepared(ed, picked);
  if (got.result != null) return got.result;
  final sel = ed.selection.resolved;
  final id = insertImageOverCells(
    ctx,
    ed,
    got.image!,
    row: sel.activeRow,
    col: sel.activeCol,
  );
  return ok({'objectId': id, 'image': true});
}

/// The image commands (08 §10, §16).
List<Command<CommandArgs>> imageCommands(ShellServices s) {
  if (s.client != null) SheetsImageBlobCache.install(s);
  return _imageCommands(s);
}

List<Command<CommandArgs>> _imageCommands(ShellServices s) => [
  SheetsCommand(
    'sheets.image.insertOverCells',
    label: (l) => l.cmdImageInsertOverCells,
    icon: LucideIcons.image,
    categoryName: _cat,
    mutates: true,
    undoLabelOf: (l, a) => l.undoInsertImage,
    argsSchema: const JsonSchema.object(
      properties: {
        ..._sourceProps,
        'anchor': JsonSchema.object(
          description: '{cell: A1} (default: the active cell).',
          additionalProperties: true,
        ),
      },
    ),
    enabled: (ed, a) => ed.activeSheet?.record?.kind != SheetKind.chart,
    run: (ctx, ed, a) async {
      final got = await _obtain(ctx, ed, a, inCell: false);
      if (got.result != null) return got.result!;
      final sheet = ed.activeSheet!;
      var row = ed.selection.resolved.activeRow;
      var col = ed.selection.resolved.activeCol;
      if (a.values['anchor'] case final Map<dynamic, dynamic> m) {
        final c = ed.model.parseA1(
          '${m['cell'] ?? 'A1'}',
          contextSheetId: sheet.id,
        );
        row = c.rect.top;
        col = c.rect.left;
      }
      final id = insertImageOverCells(
        ctx,
        ed,
        got.image!,
        row: row,
        col: col,
        sourceUrl: got.url,
      );
      return ok({'objectId': id, 'fileUuid': _fileOf(ed, id)});
    },
  ),
  SheetsCommand(
    'sheets.image.insertInCell',
    label: (l) => l.cmdImageInsertInCell,
    icon: LucideIcons.image,
    categoryName: _cat,
    mutates: true,
    undoLabelOf: (l, a) => l.undoInsertImage,
    argsSchema: const JsonSchema.object(
      properties: {
        ..._sourceProps,
        'cell': JsonSchema.string(description: 'A1 (default: active cell).'),
        'mode': JsonSchema.integer(description: 'IMAGE mode 1–4.'),
      },
    ),
    enabled: (ed, a) => ed.activeSheet?.record?.kind != SheetKind.chart,
    run: (ctx, ed, a) async {
      final got = await _obtain(ctx, ed, a, inCell: true, urlOnly: true);
      if (got.result != null) return got.result!;
      final String src;
      if (got.image != null) {
        src =
            '${SheetsImageService.scheme}'
            '${SheetsImageService.of(ed).startUpload(got.image!.image)}';
      } else {
        src = got.url!;
      }
      final target = rangeArg(ed, a, 'cell');
      ed.apply(
        ctx,
        SetCellInputs(
          sheetId: target.sheetId,
          row: target.rect.top,
          col: target.rect.left,
          inputs: [
            [UserCellInput(imageFormula(src, mode: a.integer('mode')))],
          ],
          parseLocale: 'en_US',
          label: SheetsChangeLabels.insertImage,
        ),
      );
      return ok({'cell': CellPos(target.rect.top, target.rect.left).a1});
    },
  ),
  SheetsCommand(
    'sheets.image.replace',
    label: (l) => l.cmdImageReplace,
    icon: LucideIcons.imageUp,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'objectId': JsonSchema.string(), ..._sourceProps},
    ),
    enabled: (ed, a) => _image(ed, a) != null,
    run: (ctx, ed, a) async {
      final o = _image(ed, a);
      if (o == null) return CommandResult.failed(ed.l10n.objectNotFound);
      final got = await _obtain(ctx, ed, a, inCell: false);
      if (got.result != null) return got.result!;
      final img = got.image!.image;
      final size = got.image!.size;
      final uuid = SheetsImageService.of(ed).startUpload(img);
      final old = ImageSpec.fromJson(o.specJson);
      final spec = ImageSpec(
        fileUuid: uuid,
        mime: img.mimeType,
        naturalWidth: size.width.round(),
        naturalHeight: size.height.round(),
        fit: old.fit,
        sourceUrl: got.url,
      );
      ed.apply(ctx, UpdateObject(o.id, specJson: spec.encode()));
      return ok({'objectId': o.id, 'fileUuid': uuid});
    },
  ),
  SheetsCommand(
    'sheets.image.resetSize',
    label: (l) => l.cmdImageResetSize,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'objectId': JsonSchema.string()},
    ),
    enabled: (ed, a) => _image(ed, a) != null,
    run: (ctx, ed, a) {
      final o = _image(ed, a);
      final sheet = o == null ? null : ed.model.sheet(o.sheetId);
      final base = o == null ? null : _objs(ed).anchorOf(o);
      final rect = o == null ? null : _objs(ed).rectOf(o, ghost: false);
      if (o == null || sheet == null || base == null || rect == null) {
        return CommandResult.failed(ed.l10n.objectNotFound);
      }
      final spec = ImageSpec.fromJson(o.specJson);
      final size = ObjectPlacement.resetImageSize(
        spec.naturalWidth.toDouble(),
        spec.naturalHeight.toDouble(),
      );
      final anchor = ObjectOps.anchorAt(
        sheet,
        rect.left,
        rect.top,
        width: size.width,
        height: size.height,
        base: base,
      );
      ed.apply(ctx, UpdateObject(o.id, anchorJson: anchor.encode()));
      return ok({'objectId': o.id});
    },
  ),
  SheetsCommand(
    'sheets.image.placeInCell',
    label: (l) => l.cmdImagePlaceInCell,
    categoryName: _cat,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': JsonSchema.string(),
        'cell': JsonSchema.string(description: 'A1 (default: active cell).'),
      },
    ),
    enabled: (ed, a) => _image(ed, a) != null,
    run: (ctx, ed, a) {
      final o = _image(ed, a);
      if (o == null) return CommandResult.failed(ed.l10n.objectNotFound);
      final spec = ImageSpec.fromJson(o.specJson);
      final src = spec.fileUuid.isNotEmpty
          ? spec.fileUrl
          : (spec.sourceUrl ?? '');
      if (src.isEmpty) return CommandResult.failed(ed.l10n.imageUnavailable);
      final target = rangeArg(ed, a, 'cell');
      ed.apply(ctx, DeleteObject(o.id));
      ed.apply(
        ctx,
        SetCellInputs(
          sheetId: target.sheetId,
          row: target.rect.top,
          col: target.rect.left,
          inputs: [
            [UserCellInput(imageFormula(src))],
          ],
          parseLocale: 'en_US',
          label: SheetsChangeLabels.insertImage,
        ),
      );
      _objs(ed).select(null);
      return ok({'cell': CellPos(target.rect.top, target.rect.left).a1});
    },
  ),
  SheetsCommand(
    'sheets.image.placeOverCells',
    label: (l) => l.cmdImagePlaceOverCells,
    categoryName: _cat,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'cell': JsonSchema.string(description: 'A1 (default: active cell).'),
      },
    ),
    enabled: (ed, a) {
      try {
        return _cellImage(ed, rangeArg(ed, a, 'cell')) != null;
      } catch (_) {
        return false;
      }
    },
    run: (ctx, ed, a) {
      final target = rangeArg(ed, a, 'cell');
      final v = _cellImage(ed, target);
      if (v == null) return const CommandResult.failed('No image in the cell');
      final sheet = ed.model.sheet(target.sheetId)!;
      final service = SheetsImageService.of(ed);
      final img = service.decoded(v.url);
      final w = img?.width.toDouble() ?? ObjectPlacement.imageFitWidth;
      final h = img?.height.toDouble() ?? ObjectPlacement.imageFitHeight;
      final anchor = ObjectPlacement.imageAnchor(
        row: target.rect.top,
        col: target.rect.left,
        naturalWidth: w,
        naturalHeight: h,
        rows: sheet.rows,
        columns: sheet.columns,
      );
      final uuid = SheetsImageService.fileUuidOf(v.url);
      final spec = ImageSpec(
        fileUuid: uuid ?? '',
        naturalWidth: w.round(),
        naturalHeight: h.round(),
        sourceUrl: uuid == null ? v.url : null,
      );
      ed.apply(ctx, ClearRanges([target]));
      final plan = ed.apply(
        ctx,
        AddObject(
          sheet.id,
          EmbeddedObjectKind.image,
          anchorJson: anchor.encode(),
          specJson: spec.encode(),
          altText: v.altText,
        ),
      );
      final id = plan.result['objectId']! as String;
      _objs(ed).select(id);
      return ok({'objectId': id});
    },
  ),
];

/// The `IMAGE()` value of the top-left cell of [r], or null.
ImageValue? _cellImage(SheetEditorController ed, ResolvedRange r) {
  final v = ed.engine.valueAt(r.sheetId, r.rect.top, r.rect.left);
  if (v is FRich && v.payload is ImageValue) return v.payload as ImageValue;
  return null;
}
