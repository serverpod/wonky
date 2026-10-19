import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/model.dart' as core;

import '../../platform/activity/activity_service.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/files/file_service.dart';
import '../../platform/sharing/access_service.dart';
import '../headless/headless_workbook_provider.dart';
import 'sheets_pdf_fonts.dart';

/// Server-side spreadsheet exports (Sheets 11 §6.1, `drive.export`): the
/// same core exporters as the app (`SheetsWorkbookExporter`) on the headless
/// workbook; the result is a `StoredFile` with a signed URL (24 h file,
/// 15 min URL) and an `exported` activity event.
abstract final class SheetsExportService {
  static const resultLifetime = Duration(hours: 24);

  /// Text results up to this size are also returned inline.
  static const inlineLimit = 1024 * 1024;

  /// Exports of one user running at once (per instance). Spreadsheet
  /// exports read the headless workbook's live formula engine, so they run
  /// on the request isolate (a worker would have to recalculate the whole
  /// workbook); this cap keeps one user from queueing many.
  static const maxConcurrentPerUser = 2;

  static final Map<int, int> _running = {};

  /// Exports the spreadsheet [itemUuid] as [format] (`xlsx`, `ods`, `pdf`,
  /// `html`, `csv`, `tsv`, `json`). [sheetName]/[range] select the sheet
  /// (and A1 range) of CSV/TSV/PDF; [darkTheme] renders dark PDF pages.
  static Future<ExportResultView> export(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String format, {
    String? sheetName,
    String? range,
    bool darkTheme = false,
  }) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    if (item.kind != DriveItemKind.spreadsheet || item.contentRef == null) {
      throw Errors.invalid('This item is not a spreadsheet.');
    }
    if (role < Role.editor && !item.nonEditorsCanExport) {
      throw Errors.forbidden('The owner has disabled downloads for viewers.');
    }
    final fmt = core.SheetsExportFormat.tryParse(format);
    if (fmt == null) {
      throw Errors.invalid(
        'Spreadsheets export as xlsx, ods, pdf, html, csv, tsv or json.',
      );
    }
    final running = _running[actor.userId] ?? 0;
    if (running >= maxConcurrentPerUser) {
      throw Errors.busy('Wait for your other exports to finish.');
    }
    _running[actor.userId] = running + 1;
    final core.SheetsExportArtifact artifact;
    try {
      artifact = await exportBytes(
        session,
        item,
        fmt,
        sheetName: sheetName,
        range: range,
        author: null,
        darkTheme: darkTheme,
      );
    } finally {
      final left = (_running[actor.userId] ?? 1) - 1;
      if (left <= 0) {
        _running.remove(actor.userId);
      } else {
        _running[actor.userId] = left;
      }
    }
    final expires = nowUtc().add(resultLifetime);
    final file = await FileService.storeServerFile(
      session,
      ownerId: actor.userId,
      itemId: item.id,
      kind: StoredFileKind.exportResult,
      fileName: artifact.fileName,
      mimeType: artifact.mimeType,
      bytes: artifact.bytes,
      expiresAt: expires,
    );
    final url = await FileService.getUrl(session, actor, file.fileUuid);
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.exported,
      summary: {'format': fmt.name},
    );
    final text =
        (fmt.singleSheet || fmt == core.SheetsExportFormat.json) &&
            artifact.bytes.length <= inlineLimit
        ? utf8.decode(artifact.bytes, allowMalformed: true)
        : null;
    return ExportResultView(
      fileName: artifact.fileName,
      mimeType: artifact.mimeType,
      sizeBytes: artifact.bytes.length,
      pageCount: artifact.pageCount,
      downloadUrl: url.url!,
      expiresAt: url.expiresAt ?? expires,
      inlineText: text,
      warnings: [
        for (final w in artifact.warnings)
          ImportWarningView(kind: w.code, message: w.message),
      ],
    );
  }

  /// The exported file of [item] (no storage; tests and MCP).
  static Future<core.SheetsExportArtifact> exportBytes(
    Session session,
    DriveItem item,
    core.SheetsExportFormat fmt, {
    String? sheetName,
    String? range,
    String? author,
    bool darkTheme = false,
  }) async {
    final wb = await HeadlessWorkbookProvider.open(session, item.contentRef!);
    final model = wb.model;
    final source = wb.engine;
    final title = item.name.isEmpty ? model.spreadsheet.title : item.name;
    final images = <String, Uint8List>{};
    if (fmt != core.SheetsExportFormat.csv &&
        fmt != core.SheetsExportFormat.tsv &&
        fmt != core.SheetsExportFormat.json) {
      for (final uuid in core.SheetsWorkbookExporter.imageFiles(model)) {
        final f = await FileService.byUuid(
          session,
          UuidValue.withValidation(uuid),
        );
        if (f == null) continue;
        final data = await FileService.readBytes(session, f);
        images[uuid] = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
      }
    }
    core.SheetModel? sheet;
    if (sheetName != null && sheetName.trim().isNotEmpty) {
      sheet = model.sheetByName(sheetName.trim());
      if (sheet == null) throw Errors.notFound('Sheet "$sheetName"');
    }
    sheet ??= model.visibleSheets.isEmpty ? null : model.visibleSheets.first;
    core.ResolvedRange? rr;
    if (range != null && range.trim().isNotEmpty) {
      try {
        rr = model.parseA1(range.trim(), contextSheetId: sheet?.id);
      } on core.InvalidRangeException catch (e) {
        throw Errors.invalid(e.message);
      }
      sheet = model.sheet(rr.sheetId);
    }
    final now = nowUtc();
    switch (fmt) {
      case core.SheetsExportFormat.xlsx ||
          core.SheetsExportFormat.ods ||
          core.SheetsExportFormat.json:
        final doc = core.SheetsWorkbookExporter.toDocument(
          model,
          values: core.EngineIrValueSource(source),
          imageBytes: (u) => images[u],
          chartSource: fmt == core.SheetsExportFormat.xlsx ? source : null,
        );
        final (bytes, warnings) = core.SheetsWorkbookExporter.writeDocument(
          doc,
          fmt,
          modified: now,
        );
        return core.SheetsExportArtifact(
          fileName: core.SheetsWorkbookExporter.fileNameFor(title, fmt),
          mimeType: fmt.mimeType,
          bytes: bytes,
          warnings: warnings,
        );
      case core.SheetsExportFormat.csv || core.SheetsExportFormat.tsv:
        if (sheet == null) throw Errors.invalid('The spreadsheet is empty.');
        return core.SheetsExportArtifact(
          fileName: core.SheetsWorkbookExporter.fileNameFor(
            title,
            fmt,
            sheetName: sheet.name,
          ),
          mimeType: fmt.mimeType,
          bytes: core.SheetsWorkbookExporter.delimited(
            model,
            source,
            sheetId: sheet.id,
            format: fmt,
            range: rr?.rect,
          ),
        );
      case core.SheetsExportFormat.html:
        return core.SheetsExportArtifact(
          fileName: core.SheetsWorkbookExporter.fileNameFor(title, fmt),
          mimeType: fmt.mimeType,
          bytes: core.SheetsWorkbookExporter.html(
            model,
            source,
            imageBytes: (u) => images[u],
            modified: now,
          ),
        );
      case core.SheetsExportFormat.pdf:
        final job = rr != null
            ? core.PrintJob(scope: core.PrintScope.selection, selection: rr)
            : sheetName != null
            ? core.PrintJob(sheetId: sheet?.id)
            : const core.PrintJob(scope: core.PrintScope.workbook);
        final fonts = await SheetsPdfFonts.load();
        final pages = core.SheetsWorkbookExporter.paginate(
          model,
          source,
          job,
          fonts: fonts,
        );
        final bytes = await core.SheetsWorkbookExporter.pdf(
          model,
          source,
          pages,
          now: now,
          author: author,
          title: title,
          imageBytes: (u) => images[u],
          fonts: fonts,
          darkTheme: darkTheme,
        );
        return core.SheetsExportArtifact(
          fileName: core.SheetsWorkbookExporter.fileNameFor(
            title,
            fmt,
            sheetName: sheetName == null ? null : sheet?.name,
          ),
          mimeType: fmt.mimeType,
          bytes: bytes,
          pageCount: pages.pages.length,
        );
    }
  }
}
