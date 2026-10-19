import 'dart:typed_data';

import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/pdf.dart';

import '../config/slides_features.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/navigator/deck_renderer.dart';
import '../features/print/png_export_dialog.dart';
import '../features/print/print_preview_screen.dart';
import '../features/print/slides_client_export.dart';
import '../features/print/slides_png_export.dart';
import '../l10n/slides_l10n.dart';
import 'slides_command.dart';

/// The print and PDF export commands (Slides 10 §11.6, §12, §14; SL-20):
/// `slides.print.open` (`Mod+P`) opens the print preview route,
/// `slides.file.download {format: pdf}` opens it too unless `immediate`
/// (Shift-click, MCP) exports right away with `options` (10 §11.1 keys) or
/// the last-used options, and `slides.print.print` prints the previewed PDF.
/// `slides.file.download {format: png|pngZip}` (10 §13, SL-33) opens the
/// PNG dialog (current slide / all slides) unless `immediate` (MCP) renders
/// right away with `options` over the last-used PNG options; one image
/// downloads as `.png`, several as a `.zip`. None of them changes the
/// deck. Viewers and commenters may export only when the owner allows it
/// (`nonEditorsCanExport`).
List<Command<CommandArgs>> printCommands(ShellServices s) => [
  SlidesCommand(
    'slides.print.open',
    label: (l) => l.cmdPrintOpen,
    icon: LucideIcons.printer,
    categoryOf: SlidesCategory.file,
    defaultBindings: const [KeyBinding('P', mod: true)],
    argsSchema: JsonSchema.object(
      properties: {
        'layout': JsonSchema.string(
          enumValues: [for (final v in SlidesPdfLayout.values) v.name],
        ),
      },
    ),
    run: (ctx, ed, a) {
      _openPreview(s, ed, layout: a.string('layout'));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.file.download',
    label: (l) => l.cmdFileDownload,
    icon: LucideIcons.download,
    categoryOf: SlidesCategory.file,
    argsSchema: JsonSchema.object(
      properties: {
        'format': JsonSchema.string(
          enumValues: [
            for (final f in const ['pdf', 'png', 'pngZip', 'markdown'])
              if (SlidesFeatures.offers('slides.file.download', {'format': f}))
                f,
          ],
        ),
        'options': const JsonSchema.object(
          additionalProperties: true,
          description:
              'PDF options (Slides 10 §11.1); PNG: range '
              '(current|selection|all|"1-3,7"), scale (1|2|4), frames '
              '(print|final|builds), transparent, includeSkipped, fileName',
        ),
        'immediate': const JsonSchema.boolean(),
      },
      required: const ['format'],
    ),
    // Markdown (P2) comes later (04 §10).
    enabled: (ed, a) => switch (a.string('format') ?? 'pdf') {
      'pdf' => true,
      'png' || 'pngZip' => SlidesFeatures.isOn(SlidesFeature.imageExports),
      _ => false,
    },
    reason: (l, ed) => l.reasonNotAvailableYet,
    run: (ctx, ed, a) async {
      final l = slidesL10nOf(s);
      final format = a.string('format');
      if ((format == 'png' || format == 'pngZip') &&
          SlidesFeatures.isOn(SlidesFeature.imageExports)) {
        return _exportPng(ctx, s, ed, a, zip: format == 'pngZip');
      }
      if (format != 'pdf') {
        return CommandResult.failed(l.exportFormatUnavailable);
      }
      final raw = a.values['options'];
      final immediate = a.boolean('immediate') ?? false;
      if (!immediate) {
        final open = activeSlidesPrint.value;
        if (open != null) {
          return await open.download()
              ? ok()
              : CommandResult.failed(l.exportFailed);
        }
        _openPreview(s, ed);
        return ok();
      }
      return _exportNow(
        s,
        ed,
        raw is Map ? raw.cast<String, Object?>() : const {},
      );
    },
  ),
  SlidesCommand(
    'slides.print.print',
    label: (l) => l.cmdPrintPrint,
    icon: LucideIcons.printer,
    categoryOf: SlidesCategory.file,
    enabled: (ed, a) => activeSlidesPrint.value?.controller?.pdf != null,
    reason: (l, ed) => l.printUpdatingPreview,
    run: (ctx, ed, a) async {
      final open = activeSlidesPrint.value;
      if (open == null) return const CommandResult.failed('No preview');
      return await open.print()
          ? ok()
          : CommandResult.failed(slidesL10nOf(s).printUnavailableTitle);
    },
  ),
];

void _openPreview(ShellServices s, DeckEditorController ed, {String? layout}) {
  final path = '${s.config.itemPath(ed.session.itemUuid.uuid)}/print';
  s.router.go(layout == null ? path : '$path?layout=$layout');
}

Future<CommandResult> _exportNow(
  ShellServices s,
  DeckEditorController ed,
  Map<String, Object?> options,
) async {
  final l = slidesL10nOf(s);
  try {
    final item = await s.drive.get(ed.session.itemUuid);
    if (!item.canDownload) {
      return CommandResult.failed(l.printDownloadsDisabledTitle);
    }
  } on Object {
    // Offline: the deck is local, exporting needs no server.
  }
  final last = SlidesPdfOptionsCodec.toJson(SlidesClientExport.lastUsed(s));
  final o = SlidesPdfOptionsCodec.fromJson({...last, ...options});
  final effective = switch (o.range) {
    'current' => o.copyWith(slideIds: [?ed.currentSlideId]),
    'selection' => o.copyWith(slideIds: ed.selectedSlideIds.toList()),
    _ => o,
  };
  final title = ed.model.deck?.title ?? '';
  final name =
      '${o.fileName ?? SlidesPdfOptionsCodec.sanitizeFileName(title.isEmpty ? l.pdfUntitledPresentation : title)}.pdf';
  try {
    final r = await SlidesClientExport.render(
      ed.model,
      effective,
      images: ed.session.images,
      l: l,
      info: SlidesPdfDocumentInfo(title: title.isEmpty ? null : title),
    );
    final saved = await SlidesClientExport.save(
      _bytes(r.bytes),
      fileName: name,
    );
    if (!saved) return const CommandResult.failed('Cancelled');
    await SlidesClientExport.remember(s, o);
    final warnings = {
      for (final w in r.warnings) SlidesClientExport.warning(l, w),
    };
    s.toasts.show(
      l.exportedToast(name),
      description: warnings.isEmpty ? null : warnings.join('\n'),
    );
    return CommandResult.ok({
      'fileName': name,
      'pageCount': r.pageCount,
      'warnings': r.warnings,
    });
  } on Object catch (e) {
    s.toasts.show(
      l.exportFailed,
      description: errorMessage(e),
      destructive: true,
    );
    return CommandResult.failed(l.exportFailed);
  }
}

/// The user's last-used PNG options (`slidesDefaults.imageExportOptions`,
/// A-10-4).
SlidesPngOptions _lastPng(ShellServices s) {
  final raw = s.prefs.slidesDefaults['imageExportOptions'];
  return SlidesPngOptions.fromJson(
    raw is Map ? raw.cast<String, Object?>() : const {},
  );
}

Future<CommandResult> _exportPng(
  CommandContext ctx,
  ShellServices s,
  DeckEditorController ed,
  JsonArgs a, {
  required bool zip,
}) async {
  final l = slidesL10nOf(s);
  try {
    final item = await s.drive.get(ed.session.itemUuid);
    if (!item.canDownload) {
      return CommandResult.failed(l.printDownloadsDisabledTitle);
    }
  } on Object {
    // Offline: the deck is local, exporting needs no server.
  }
  final raw = a.values['options'];
  final given = raw is Map
      ? raw.cast<String, Object?>()
      : const <String, Object?>{};
  var o = SlidesPngOptions.fromJson({
    ..._lastPng(s).toPreferences(),
    'range': zip ? 'all' : 'current',
    'zip': zip,
    ...given,
  });
  final immediate = a.boolean('immediate') ?? false;
  final dc = ctx.dialogContext;
  if (!immediate && !ctx.source.isAgent && dc != null && dc.mounted) {
    final chosen = await showPngExportDialog(dc, ed, o);
    if (chosen == null) return const CommandResult.cancelled();
    o = chosen;
  }
  final ids = switch (o.range) {
    'current' => [?ed.currentSlideId],
    'selection' =>
      ed.selectedSlideIds.isEmpty
          ? [?ed.currentSlideId]
          : ed.selectedSlideIds.toList(),
    _ => null,
  };
  final renderer = DeckThumbnails.acquire(ed);
  try {
    final r = await SlidesPngExport.render(renderer, o, slideIds: ids);
    if (r.images.isEmpty) {
      if (!ctx.source.isAgent) s.toasts.show(l.pngNothingToExport);
      return CommandResult.failed(l.pngNothingToExport);
    }
    final title = ed.model.deck?.title ?? '';
    final (name, bytes, mimeType) = SlidesPngExport.package(
      r,
      baseName:
          o.fileName ??
          SlidesPdfOptionsCodec.sanitizeFileName(
            title.isEmpty ? l.pdfUntitledPresentation : title,
          ),
      zip: o.zip,
      entryName: (i, digits) {
        final n = '${i.number}'.padLeft(digits, '0');
        return i.step == null
            ? l.pngEntrySlide(n)
            : l.pngEntryStep(n, i.step! + 1);
      },
    );
    final saved = await SlidesClientExport.save(bytes, fileName: name);
    if (!saved) return const CommandResult.cancelled();
    await s.prefs.setSlidesDefault('imageExportOptions', o.toPreferences());
    if (!ctx.source.isAgent) s.toasts.show(l.exportedToast(name));
    return CommandResult.ok({
      'fileName': name,
      'mimeType': mimeType,
      'images': r.images.length,
      'width': r.width,
      'height': r.height,
      'warnings': r.warnings,
    });
  } on Object catch (e) {
    s.toasts.show(
      l.exportFailed,
      description: errorMessage(e),
      destructive: true,
    );
    return CommandResult.failed(l.exportFailed);
  } finally {
    DeckThumbnails.release(ed, renderer);
  }
}

Uint8List _bytes(List<int> bytes) =>
    bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
