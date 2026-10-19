import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show DriveImportOptions, DriveItemKind, StoredFileKind, UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/model.dart';

import '../import_export/pending_uploads.dart';
import '../import_export/progress_dialog.dart';
import '../import_export/sheets_io.dart';
import '../model/sheets_undo.dart';
import '../model/workbook_session.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import '../revlog/sheets_rev_log.dart';

/// A file chosen for import (picker, drop, MCP).
@immutable
class ImportFileData {
  const ImportFileData({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  /// The detected format (null: not importable).
  SheetsFileFormat? get format => SheetsFileImporter.formatOf(name, bytes);

  /// "orders.csv (4.2 MB)".
  String get sizeLabel => formatBytes(bytes.length);
}

/// "812 B" / "4.2 KB" / "4.2 MB".
String formatBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Files handed from a picker/drop to the `sheets.file.import*` commands by
/// token (command args stay small JSON).
abstract final class ImportFileRegistry {
  static final Map<String, ImportFileData> _files = {};
  static int _next = 0;

  /// Stores [f]; returns its token.
  static String put(ImportFileData f) {
    final t = 'file-${_next++}';
    _files[t] = f;
    return t;
  }

  /// The file of [token] (null when unknown).
  static ImportFileData? take(String? token) =>
      token == null ? null : _files.remove(token);

  static ImportFileData? peek(String? token) =>
      token == null ? null : _files[token];
}

/// The last import report (`sheets.file.showImportReport`).
final ValueNotifier<ImportReport?> lastImportReport = ValueNotifier(null);

/// Client limits of 11 §3.1: online, larger files are imported by the
/// server (`drive.import` for new spreadsheets, a server import job into
/// the open one, `server_import.dart`); offline they import here with a
/// "may take a while" note.
abstract final class ImportThresholds {
  static const csvBytes = 20 * 1024 * 1024;
  static const workbookBytes = 5 * 1024 * 1024;
  static const csvCells = 300000;
  static const workbookCells = 200000;

  static bool isLarge(ImportFileData f) {
    final fmt = f.format;
    if (fmt == null) return false;
    return f.bytes.length > (fmt.isText ? csvBytes : workbookBytes);
  }
}

/// Parses [file] off the UI thread.
Future<ParsedImportFile> parseImportFile(
  ImportFileData file,
  ImportOptions options, {
  required String spreadsheetLocale,
}) {
  final bytes = file.bytes;
  final name = file.name;
  final now = DateTime.now();
  return runOffThread(
    () => SheetsFileImporter.parse(
      bytes,
      fileName: name,
      options: options,
      spreadsheetLocale: spreadsheetLocale,
      today: now,
    ),
  );
}

/// The first [rows] × [cols] cells of [sheetName] (default: the first sheet)
/// as displayed text (dialog preview, 11 §2.2).
List<List<String>> previewRows(
  ParsedImportFile parsed, {
  String? sheetName,
  int rows = 20,
  int cols = 12,
  String locale = 'en_US',
}) {
  final doc = parsed.document;
  if (doc.sheets.isEmpty) return const [];
  final s =
      (sheetName == null ? null : doc.sheetByName(sheetName)) ??
      doc.sheets.first;
  final lastRow = s.cells.maxRow;
  final lastCol = s.cells.maxCol;
  if (lastRow < 0) return const [];
  final nr = lastRow + 1 < rows ? lastRow + 1 : rows;
  final nc = lastCol + 1 < cols ? lastCol + 1 : cols;
  final formatter = NumberFormatter.instance;
  return [
    for (var r = 0; r < nr; r++)
      [
        for (var c = 0; c < nc; c++)
          () {
            final cell = s.cells.get(r, c);
            if (cell == null) return '';
            final v = cell.value;
            if (v == null) {
              return cell.formulaA1 == null ? '' : '=${cell.formulaA1}';
            }
            final pattern =
                IrFormats.effective(doc, s, r, c, cell)[FormatAttr.numberFormat]
                    as String?;
            try {
              return formatter
                  .format(v.toCellValue(), pattern, locale: locale)
                  .plainText;
            } catch (_) {
              return '${v.toCellValue()}';
            }
          }(),
      ],
  ];
}

/// The start cell of *Replace data at selected cell*: the option's `cell`
/// or the active cell.
(int, int) startCellOf(SheetEditorController ed, ImportOptions o) {
  final c = o.startCell;
  if (c != null) return c;
  final r = ed.selection.resolved;
  return (r.activeRow, r.activeCol);
}

/// Grid size the import would produce (cell-limit check, 11 §3.4).
ImportSizeEstimate estimateImport(
  ParsedImportFile parsed,
  WorkbookModel model,
  ImportOptions options, {
  String? activeSheetId,
  (int, int)? start,
  int maxCells = 1000000,
}) => IrToRowsPlanner.estimate(
  parsed.document,
  model,
  options: options,
  activeSheetId: activeSheetId,
  maxCells: maxCells,
  startRow: start?.$1,
  startCol: start?.$2,
);

/// Cells per import chunk (tests make it small).
int importChunkCells = IrImportChunks.defaultChunkCells;

/// Plans [parsed] into the open spreadsheet of [ed] and applies it as one
/// `sheets.rows` undo step in [ctx] (11 §2.4). The cells are planned in
/// chunks (`IrToRowsPlanner.planChunked`, 11 §3.5): each chunk is applied
/// and queued for the replica at once, and the frames between chunks keep
/// the UI responsive; [progress] shows the share planned and cancels
/// (everything applied so far is reverted, then [IoCancelled] is thrown).
/// Images of the file are uploaded in the background (online). Throws
/// `PlanException`.
Future<IrImportResult> applyImport(
  SheetEditorController ed,
  CommandContext? ctx,
  ParsedImportFile parsed,
  ImportOptions options, {
  required String fileName,
  IoProgress? progress,
  int? chunkCells,
}) async {
  final session = ed.session;
  final start = options.location == ImportLocation.replaceAtCell
      ? startCellOf(ed, options)
      : null;
  final chunks = IrToRowsPlanner.planChunked(
    parsed.document,
    ed.model,
    session.planContext(),
    options: options,
    activeSheetId: ed.activeSheetId,
    fileName: fileName,
    startRow: start?.$1,
    startCol: start?.$2,
    chunkCells: chunkCells ?? importChunkCells,
  );
  final label = chunks.head.label;
  final applied = <RowChange>[];
  void apply(MutationPlan plan) {
    if (plan.isEmpty) return;
    session.applyChanges(plan.changes, label: label);
    applied.addAll(plan.changes);
  }

  try {
    apply(chunks.head);
    for (var plan = chunks.next(); plan != null; plan = chunks.next()) {
      apply(plan);
      progress?.value.value = chunks.progress;
      // A frame between chunks (and a chance to cancel).
      await Future<void>.delayed(Duration.zero);
      progress?.check();
    }
  } on Object {
    if (applied.isNotEmpty) {
      session.applyChanges([
        for (final c in applied.reversed) c.inverse(),
      ], label: label);
    }
    rethrow;
  }
  final result = chunks.result;
  if (applied.isEmpty) return result;
  if (ctx?.transaction != null) {
    ctx!.record(SheetsRowsUndoEntry(applied, label: label));
  }
  if (result.imageUploads.isNotEmpty) {
    _uploadImages(ed.services, result.imageUploads, session.itemUuid);
  }
  lastImportReport.value = result.report;
  return result;
}

/// Queues the image files of an import as durable uploads (the bytes are
/// stored on the device first, so the images show offline and survive a
/// reload, then upload when online). Without the queue (tests, no user)
/// they upload directly.
void _uploadImages(
  ShellServices s,
  List<IrImageUpload> uploads,
  UuidValue item,
) {
  final queue = SheetsPendingUploads.of(s);
  if (queue == null) {
    unawaited(_uploadDirectly(s, uploads, item));
    return;
  }
  for (final u in uploads) {
    // `add` caches the bytes synchronously: the image renders at once.
    unawaited(
      queue.add(
        fileUuid: u.fileUuid,
        itemUuid: item.uuid,
        bytes: u.bytes,
        mimeType: u.mimeType,
        fileName: u.name ?? 'image',
      ),
    );
  }
}

Future<void> _uploadDirectly(
  ShellServices s,
  List<IrImageUpload> uploads,
  UuidValue item,
) async {
  for (final u in uploads) {
    try {
      await s.repositories.files.upload(
        fileUuid: UuidValue.withValidation(u.fileUuid),
        itemUuid: item,
        fileName: u.name ?? 'image',
        mimeType: u.mimeType,
        bytes: u.bytes,
      );
    } catch (e) {
      debugPrint('Import image upload failed: $e');
    }
  }
}

/// A new spreadsheet created by an import.
typedef ImportedSpreadsheet = ({
  UuidValue uuid,
  String name,
  ImportReport report,
});

/// Imports [file] as a new spreadsheet (*Create new spreadsheet*, drive
/// upload/drop, 11 §2.1): online through the server pipeline (`drive.import`
/// — big files, images stored with the item); offline (or when the server
/// path fails with a connection error) locally in a reserved space. Not
/// undoable (Drive: move to trash).
Future<ImportedSpreadsheet> importAsNewSpreadsheet(
  ShellServices s,
  ImportFileData file,
  ImportOptions options, {
  UuidValue? parentUuid,
  String? name,
}) async {
  final title = (name?.trim().isNotEmpty ?? false)
      ? name!.trim()
      : SheetsFileImporter.baseName(file.name);
  final opts = options.copyWith(location: ImportLocation.createNew);
  final client = s.client;
  if (client != null && s.connectivity.online) {
    try {
      final upload = await s.repositories.files.upload(
        fileUuid: s.ids.next(),
        fileName: file.name,
        mimeType: SheetsFileImporter.mimeType(
          file.format ?? SheetsFileFormat.csv,
        ),
        bytes: file.bytes,
        kind: StoredFileKind.importSource,
      );
      final r = await client.drive.import(
        upload.fileUuid,
        DriveItemKind.spreadsheet,
        DriveImportOptions(
          name: title.isEmpty ? null : title,
          parentUuid: parentUuid,
          optionsJson: jsonEncode(opts.toJson()),
        ),
      );
      s.refreshDrive();
      final report = ImportReport(
        fileName: file.name,
        sheets: const [],
        warnings: [
          for (final w in r.warnings)
            ImportWarning(code: w.kind, message: w.message),
        ],
      );
      lastImportReport.value = report;
      return (uuid: r.item.uuid, name: r.item.name, report: report);
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
    }
  }
  return _importLocally(s, file, opts, parentUuid: parentUuid, title: title);
}

Future<ImportedSpreadsheet> _importLocally(
  ShellServices s,
  ImportFileData file,
  ImportOptions options, {
  UuidValue? parentUuid,
  required String title,
}) async {
  final parsed = await parseImportFile(
    file,
    options,
    spreadsheetLocale: options.locale ?? 'en_US',
  );
  final controller = await SheetsRevLog.ready(s);
  if (controller == null) {
    throw StateError('Spreadsheets are not available on this device yet.');
  }
  final uuid = await SheetsRevLog.createSpreadsheet(
    s,
    parentUuid: parentUuid,
    name: title.isEmpty ? null : title,
  );
  if (uuid == null) throw StateError('The spreadsheet could not be created.');
  final session = LoggedWorkbookSession.open(
    controller,
    itemUuid: uuid,
    fileUuid: uuid,
    userId: s.me?.uuid.uuid ?? '',
    role: Role.owner,
  );
  try {
    await _whenReady(session);
    // Chunked (11 §3.5): each chunk goes into the outbox while the next
    // one is planned; not undoable, so the changes are not kept.
    final chunks = IrToRowsPlanner.planChunked(
      parsed.document,
      session.model,
      session.planContext(),
      options: options.copyWith(location: ImportLocation.replaceSpreadsheet),
      fileName: file.name,
    );
    final label = chunks.head.label;
    session.applyChanges(chunks.head.changes, label: label);
    for (var plan = chunks.next(); plan != null; plan = chunks.next()) {
      session.applyChanges(plan.changes, label: label);
      await Future<void>.delayed(Duration.zero);
    }
    final result = chunks.result;
    await session.flush();
    lastImportReport.value = result.report;
    if (result.imageUploads.isNotEmpty) {
      _uploadImages(s, result.imageUploads, uuid);
    }
    return (
      uuid: uuid,
      name: title.isEmpty ? 'Untitled spreadsheet' : title,
      report: result.report,
    );
  } finally {
    await session.dispose();
  }
}

Future<void> _whenReady(WorkbookSession session) async {
  if (session.loadState.value is WorkbookReady) return;
  final done = Completer<void>();
  void check() {
    final v = session.loadState.value;
    if (done.isCompleted) return;
    if (v is WorkbookReady) done.complete();
    if (v is WorkbookUnavailable) done.completeError(StateError(v.reason));
  }

  session.loadState.addListener(check);
  try {
    check();
    await done.future.timeout(const Duration(seconds: 60));
  } finally {
    session.loadState.removeListener(check);
  }
}
