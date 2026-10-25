import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/model.dart' as core;

import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/isolate_runner.dart';
import '../../platform/common/models.dart';
import '../../platform/common/names.dart';
import '../../platform/common/time.dart';
import '../../platform/config/wonky_config.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/drive/drive_trash.dart';
import '../../platform/files/file_service.dart';
import '../../platform/sharing/access_service.dart';
import '../mcp/sheets_bulk_writer.dart';
import '../../platform/storage/content_sizes.dart';
import '../../platform/storage/storage_hooks.dart';
import '../../platform/storage/storage_service.dart';

/// Server-side spreadsheet imports (Sheets 11 §3.3): CSV/TSV/XLSX/ODS bytes
/// → IR (`SheetsFileImporter`) → `IrToRowsPlanner` (location *Create new
/// spreadsheet*) → a new RevLog file with no rows → the planned chunks as
/// server changes (RevLog spec 05 §8.3). Used by `drive.import` with kind
/// spreadsheet (home upload, MCP).
abstract final class SheetsImportService {
  /// Formats `drive.import` accepts for spreadsheets.
  static const formats = {'csv', 'tsv', 'txt', 'xlsx', 'xlsm', 'ods', 'json'};

  /// Files above this size are parsed in a worker isolate.
  static const isolateThreshold = 512 * 1024;

  /// Time limit of a parse in the worker isolate (killed after it).
  static const parseTimeout = Duration(minutes: 3);

  /// Parses [bytes] (format from [format] or the file name). Files above
  /// [isolateThreshold] are parsed by the shared `IsolateRunner`.
  static Future<core.ParsedImportFile> parse(
    Uint8List bytes, {
    required String fileName,
    String? format,
    core.ImportOptions options = const core.ImportOptions(),
    String locale = 'en_US',
  }) async {
    final f = format == null
        ? core.SheetsFileImporter.formatOf(fileName, bytes)
        : core.SheetsFileImporter.formatOf('x.$format', bytes);
    final today = nowUtc();
    try {
      if (bytes.length <= isolateThreshold) {
        return _parse(bytes, fileName, options, f, locale, today);
      }
      return await IsolateRunner.run(
        () => _parse(bytes, fileName, options, f, locale, today),
        name: 'sheets-import-parse',
        timeout: parseTimeout,
      );
    } on core.ImportFileException catch (e) {
      throw Errors.invalid(e.message);
    } on TimeoutException {
      throw Errors.unavailable(
        'Reading the file took too long. Try a smaller file.',
      );
    }
  }

  static core.ParsedImportFile _parse(
    Uint8List bytes,
    String fileName,
    core.ImportOptions options,
    core.SheetsFileFormat? format,
    String locale,
    DateTime today,
  ) => core.SheetsFileImporter.parse(
    bytes,
    fileName: fileName,
    options: options,
    format: format,
    spreadsheetLocale: locale,
    today: today,
  );

  /// The `ImportOptions` of a `DriveImportOptions.optionsJson` (11 §9; the
  /// legacy keys `delimiter`/`convertNumbers` are understood too).
  static core.ImportOptions optionsOf(String? json) {
    Map<String, Object?> m = const {};
    if (json != null && json.trim().isNotEmpty) {
      try {
        final d = jsonDecode(json);
        if (d is Map) m = d.cast<String, Object?>();
      } on FormatException {
        throw Errors.invalid('optionsJson is not valid JSON.');
      }
    }
    var o = core.ImportOptions.fromJson(m);
    final legacySep = m['delimiter'];
    if (o.separator == null && legacySep is String && legacySep.isNotEmpty) {
      o = o.copyWith(separator: legacySep);
    }
    if (m['convertNumbers'] == false && m['convert'] == null) {
      o = o.copyWith(convert: false);
    }
    return o.copyWith(location: core.ImportLocation.createNew);
  }

  /// Imports [bytes] as a new spreadsheet named [name] (default: the file
  /// name without extension) in [parentUuid].
  static Future<ImportReportView> importNew(
    Session session,
    Actor actor,
    Uint8List bytes, {
    required String fileName,
    String? format,
    core.ImportOptions options = const core.ImportOptions(),
    String? name,
    UuidValue? parentUuid,
  }) async {
    final ext = (format ?? _extension(fileName)).toLowerCase();
    if (!formats.contains(ext)) {
      throw Errors.invalid(
        ext == 'xls'
            ? 'Legacy .xls files cannot be imported. Save the file as .xlsx '
                  'and import it again.'
            : 'Files of type "$ext" cannot be imported as spreadsheets.',
      );
    }
    final base = core.SheetsFileImporter.baseName(fileName);
    final title = normalizeItemName(
      (name?.trim().isNotEmpty ?? false)
          ? name!.trim()
          : (base.isEmpty ? 'Imported spreadsheet' : base),
    );
    final opts = options.copyWith(location: core.ImportLocation.createNew);
    // (v2) Quota before any work (Drive 03 §7.2); no item on refusal.
    await StorageHooks.checkCaller(
      session,
      actor,
      bytes.length,
      QuotaReason.import,
    );
    final parsed = await parse(
      bytes,
      fileName: fileName,
      format: ext == 'txt' ? 'csv' : ext,
      options: opts,
      locale: opts.locale ?? 'en_US',
    );
    final doc = parsed.document..title = title;

    // Validates the folder before a space is created.
    if (parentUuid != null) {
      final (parent, _) = await AccessService.require(
        session,
        actor,
        parentUuid,
        Role.editor,
      );
      if (parent.kind != DriveItemKind.folder || parent.trashedAt != null) {
        throw Errors.invalid('Items can only be created in folders.');
      }
    }
    final space = const Uuid().v7obj();
    final model = core.WorkbookModel(spreadsheetId: space.uuid);
    final ctx = core.PlanContext(
      userId: actor.authUserId.uuid,
      now: nowUtc(),
      locale: opts.locale,
      maxCells: WonkyConfig.current.maxCellsPerSpreadsheet,
    );
    // Chunked planning (11 §3.5): the head, then the cells chunk by chunk,
    // each written before the next is planned (a new spreadsheet: the cells
    // don't read the model, so the plans are not applied to it).
    final core.IrImportChunks chunks;
    try {
      chunks = core.IrToRowsPlanner.planChunked(
        doc,
        model,
        ctx,
        options: opts,
        fileName: fileName,
        label: 'Import $fileName',
        chunkCells: SheetsBulkWriter.chunkSize,
      );
    } on core.PlanException catch (e) {
      if (e.code == 'cell_limit_exceeded') throw Errors.limit(e.message);
      throw Errors.invalid(e.message);
    }
    for (final img in chunks.imageUploads) {
      await FileService.storeServerFile(
        session,
        ownerId: actor.userId,
        kind: StoredFileKind.image,
        fileName: img.name ?? 'image',
        mimeType: img.mimeType,
        bytes: img.bytes,
        fileUuid: UuidValue.fromString(img.fileUuid),
        optimize: true,
      );
    }
    // RevLog spec 05 §8.3: the file is created with no rows, then the
    // chunks are committed as server changes (the first creates the
    // spreadsheet row). A failed import deletes the new file again.
    final view = await DriveService.registerSpreadsheet(
      session,
      actor,
      spaceUuid: space,
      parentUuid: parentUuid,
      name: title,
    );
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(view.uuid),
    );
    if (item == null) throw Errors.notFound('Spreadsheet');
    try {
      for (
        core.MutationPlan? plan = chunks.head;
        plan != null;
        plan = chunks.next()
      ) {
        await SheetsBulkWriter.apply(
          session,
          actor: actor,
          spaceUuid: space,
          changes: plan.changes,
          label: chunks.head.label,
          plans: [plan],
          kinds: const {core.ChangeKinds.import},
        );
      }
    } on Object {
      try {
        await DriveTrash.purge(session, item);
      } on Object catch (e) {
        session.log(
          'Deleting the failed import ${item.uuid} failed: $e',
          level: LogLevel.warning,
        );
      }
      rethrow;
    }
    final result = chunks.result;
    final images = <StoredFile>[];
    for (final img in result.imageUploads) {
      final f = await FileService.byUuid(
        session,
        UuidValue.fromString(img.fileUuid),
      );
      if (f != null) images.add(f);
    }
    // The images and the content count for the importer (Drive 03 §2).
    await StorageHooks.attachImages(session, item, images);
    await ContentSizes.refresh(session, item);
    return ImportReportView(
      item: view,
      warnings: [for (final w in result.report.warnings) warningView(w)],
    );
  }

  /// A report warning as the drive API's warning view.
  static ImportWarningView warningView(core.ImportWarning w) {
    final where = [?w.sheet, ?w.range].join('!');
    final count = w.count > 1 ? ' (${w.count}×)' : '';
    return ImportWarningView(
      kind: w.code,
      message: '${where.isEmpty ? '' : '$where: '}${w.message}$count',
    );
  }

  static String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? '' : fileName.substring(dot + 1);
  }
}
