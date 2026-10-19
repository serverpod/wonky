import 'package:serverpod/serverpod.dart';

import '../../sheets/imports/sheets_import_service.dart';
import '../../write/export/write_import_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../files/file_service.dart';

/// Server-side imports (`drive.import`, Write 07 §3.2, Sheets 11):
/// Markdown, text, HTML, DOCX, ODT and RTF become documents
/// ([WriteImportService]), CSV/TSV/XLSX/ODS become spreadsheets
/// ([SheetsImportService]).
abstract final class ImportService {
  static Set<String> get documentFormats => WriteImportService.formats;
  static String _format(StoredFile file, DriveImportOptions options) {
    final explicit = options.format?.toLowerCase().trim();
    if (explicit != null && explicit.isNotEmpty && explicit != 'auto') {
      return explicit;
    }
    final name = file.fileName.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot >= 0) return name.substring(dot + 1);
    return switch (file.mimeType) {
      'text/csv' => 'csv',
      'text/tab-separated-values' => 'tsv',
      'text/plain' => 'txt',
      _ => 'md',
    };
  }

  static Future<ImportReportView> import(
    Session session,
    Actor actor,
    UuidValue uploadId,
    DriveItemKind kind,
    DriveImportOptions options,
  ) async {
    final file = await FileService.requireOwnReadyFile(
      session,
      actor,
      uploadId,
      kind: StoredFileKind.importSource,
    );
    final format = _format(file, options);
    final bytes = await FileService.readBytes(session, file);
    final ImportReportView report;
    switch (kind) {
      case DriveItemKind.document:
        if (!documentFormats.contains(format)) {
          throw Errors.invalid(
            'Files of type "$format" cannot be imported as documents.',
          );
        }
        report = await WriteImportService.importDocument(
          session,
          actor,
          file,
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          format,
          options,
        );
      case DriveItemKind.spreadsheet:
        report = await SheetsImportService.importNew(
          session,
          actor,
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          fileName: file.fileName,
          format: format,
          options: SheetsImportService.optionsOf(options.optionsJson),
          name: options.name,
          parentUuid: options.parentUuid,
        );
      case DriveItemKind.folder:
        throw Errors.invalid('Folders cannot be imported.');
      case DriveItemKind.presentation:
        // Slides has no import formats (Slides 01).
        throw Errors.invalid('Presentations cannot be imported.');
      case DriveItemKind.file:
        throw Errors.invalid(
          'Files are uploaded with drive.createFileUpload, not imported.',
        );
    }
    await FileService.deleteFile(session, file.fileUuid);
    return report;
  }

  /// RFC 4180 parsing with [delimiter] (quotes, escaped quotes, CRLF).
  static List<List<String>> parseDelimited(String text, String delimiter) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    var i = 0;
    final s = text.startsWith('﻿') ? text.substring(1) : text;
    while (i < s.length) {
      final ch = s[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < s.length && s[i + 1] == '"') {
            field.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
        } else {
          field.write(ch);
        }
        i++;
        continue;
      }
      if (ch == '"' && field.isEmpty) {
        inQuotes = true;
      } else if (s.startsWith(delimiter, i)) {
        row.add(field.toString());
        field.clear();
        i += delimiter.length;
        continue;
      } else if (ch == '\n' || ch == '\r') {
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
        if (ch == '\r' && i + 1 < s.length && s[i + 1] == '\n') i++;
      } else {
        field.write(ch);
      }
      i++;
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
