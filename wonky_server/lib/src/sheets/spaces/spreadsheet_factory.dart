import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    show CellContent, NumberContent, TextContent;
import 'package:wonky_sync_models/ids.dart';

import '../../platform/common/time.dart';
import '../../platform/drive/templates/builtin_templates.dart';
import 'package:wonky_sheets_core/model.dart' show RowChange, SheetsTables;
import 'template_formulas.dart';

/// Creates spreadsheet content server-side in a space (Sheets 02 §3): the
/// Spreadsheet row (id = space), sheets with 1,000 × 26 row/column entities
/// and template cells. Used by `drive.createSpreadsheet`, templates and the
/// welcome spreadsheet.
abstract final class SpreadsheetFactory {
  static const defaultRows = 1000;
  static const defaultColumns = 26;
  static const defaultThemeJson =
      '{"v":1,"name":"Default","fonts":{"text":"Inter"},"colors":{}}';

  /// The text font of a new spreadsheet with default font [fontFamily].
  static String themeFont(String? fontFamily) {
    final f = fontFamily?.trim();
    return f == null || f.isEmpty ? 'Inter' : f;
  }

  /// [defaultThemeJson] with [fontFamily] as the text font.
  static String themeJsonFor(String? fontFamily) {
    final f = themeFont(fontFamily);
    if (f == 'Inter') return defaultThemeJson;
    return jsonEncode({
      'v': 1,
      'name': 'Default',
      'fonts': {'text': f},
      'colors': <String, Object?>{},
    });
  }

  /// The row changes of a new spreadsheet [fileUuid] (the root row id) by
  /// [authorUuid]: the spreadsheet row, sheets of 1,000 × 26 rows and
  /// columns, and template cells. [sheets] empty = one blank "Sheet1". The
  /// creation op of `RevLogService.createFile` (RevLog spec 05 §8.3).
  static List<RowChange> changes({
    required UuidValue fileUuid,
    required UuidValue authorUuid,
    required String title,
    String locale = 'en_US',
    String timeZone = 'UTC',
    String? fontFamily,
    double? fontSize,
    List<TemplateSheet> sheets = const [],
    IdGenerator ids = const UuidV7IdGenerator(),
  }) {
    final now = nowUtc();
    final seeds = sheets.isEmpty
        ? const [
            TemplateSheet(
              name: 'Sheet1',
              rows: [],
              boldRows: {},
              frozenRows: 0,
            ),
          ]
        : sheets;
    final sheetKeys = FractionalIndex.nBetween(null, null, seeds.length);
    final rowKeys = FractionalIndex.nBetween(null, null, defaultRows);
    final columnKeys = FractionalIndex.nBetween(null, null, defaultColumns);
    final file = fileUuid.uuid;
    final out = <RowChange>[
      RowChange.insert(SheetsTables.spreadsheet, file, {
        'title': title,
        'locale': locale,
        'timeZone': timeZone,
        'defaultFontFamily': themeFont(fontFamily),
        'defaultFontSize': fontSize ?? 10.0,
        'themeJson': themeJsonFor(fontFamily),
        'createdBy': authorUuid.uuid,
        'createdAt': now,
      }),
    ];
    for (var s = 0; s < seeds.length; s++) {
      final seed = seeds[s];
      final sheetId = ids.newId();
      final rowCount = seed.rows.length > defaultRows
          ? seed.rows.length
          : defaultRows;
      final rowIds = [for (var i = 0; i < rowCount; i++) ids.newId()];
      final colIds = [for (var i = 0; i < defaultColumns; i++) ids.newId()];
      final keys = rowCount == defaultRows
          ? rowKeys
          : FractionalIndex.nBetween(null, null, rowCount);
      out.add(
        RowChange.insert(SheetsTables.sheet, sheetId, {
          'spreadsheetId': file,
          'name': seed.name,
          'sortKey': sheetKeys[s],
          'frozenRows': seed.frozenRows,
          'createdAt': now,
        }),
      );
      for (var r = 0; r < rowCount; r++) {
        out.add(
          RowChange.insert(SheetsTables.sheetRow, rowIds[r], {
            'sheetId': sheetId,
            'sortKey': keys[r],
            'createdAt': now,
          }),
        );
      }
      for (var c = 0; c < defaultColumns; c++) {
        out.add(
          RowChange.insert(SheetsTables.sheetColumn, colIds[c], {
            'sheetId': sheetId,
            'sortKey': columnKeys[c],
            'width': ?seed.columnWidths[c],
            'createdAt': now,
          }),
        );
      }
      final formulas = TemplateFormulas(
        sheetId: sheetId,
        sheetName: seed.name,
        rowIds: rowIds,
        rowKeys: keys,
        columnIds: colIds,
        columnKeys: columnKeys,
      );
      for (var r = 0; r < seed.rows.length; r++) {
        final row = seed.rows[r];
        for (var c = 0; c < row.length && c < defaultColumns; c++) {
          final input = row[c];
          final bold = seed.boldRows.contains(r) ? true : null;
          final format = r >= seed.frozenRows ? seed.numberFormats[c] : null;
          if ((input == null || input.isEmpty) && bold == null) continue;
          out.add(
            RowChange.insert(
              SheetsTables.cell,
              SheetsIds.cellId(sheetId, rowIds[r], colIds[c]),
              {
                'sheetId': sheetId,
                'rowId': rowIds[r],
                'columnId': colIds[c],
                'content': input == null || input.isEmpty
                    ? null
                    : encodeInput(input, r, c, formulas),
                'bold': ?bold,
                'numberFormat': ?format,
                'createdAt': now,
              },
            ),
          );
        }
      }
    }
    return out;
  }

  /// Encodes template input as stored cell content (en_US input rules:
  /// numbers, `=` formulas, a leading `'` forces text, everything else
  /// text).
  static String encodeInput(
    String input,
    int row,
    int col,
    TemplateFormulas formulas,
  ) {
    if (input.startsWith("'")) return TextContent(input.substring(1)).encode();
    if (input.startsWith('=') && input.length > 1) {
      return formulas.toStored(input, row, col);
    }
    final number = double.tryParse(input.trim());
    if (number != null && number.isFinite && !input.contains(':')) {
      return NumberContent(number).encode();
    }
    return TextContent(input).encode();
  }

  static CellContent? decode(String? content) => CellContent.decode(content);
}
