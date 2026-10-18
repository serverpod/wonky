import 'dart:math' as math;

import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/ai/untrusted_text.dart';
import '../headless/headless_workbook.dart';
import '../mcp/sheets_read_model.dart';

/// The spreadsheet context of an assistant request (Sheets 12 §6.1).
class SheetsAiContext {
  SheetsAiContext({
    required this.summary,
    required this.profiles,
    required this.fingerprint,
  });

  /// Spreadsheet summary (title, locale, sheets, names, charts, pivots).
  final String summary;

  /// Sheet profiles (tables, column profiles, sample rows).
  final String profiles;

  /// A stable hash of [summary] + [profiles]: a new "Spreadsheet changed"
  /// element is appended when it changes during a thread.
  final int fingerprint;

  /// The cached-prefix block of the first user turn.
  String get snapshot =>
      '<spreadsheet_context>\n$summary\n\n$profiles\n</spreadsheet_context>';
}

/// Builds the assistant context from a [HeadlessWorkbook] (Sheets 12
/// §6.1) within token budgets (≈ 4 characters per token): the spreadsheet
/// summary (≤ 2k tokens) and sheet profiles (≤ 12k tokens, max 10 sheets,
/// active sheet first) go in the cached prefix; the selection (≤ 8k
/// tokens) and the active cell are volatile and appended to the latest
/// user turn. Cell contents are wrapped in `<sheet_data>` tags (untrusted
/// data, never instructions).
abstract final class SheetsContextBuilder {
  static const charsPerToken = 4;
  static const summaryTokens = 2000;
  static const profileTokens = 12000;
  static const selectionTokens = 8000;
  static const maxSheets = 10;
  static const maxColumns = 50;
  static const selectionValueCells = 2000;
  static const maxText = 100;

  static String _cut(String s, int tokens) {
    final max = tokens * charsPerToken;
    if (s.length <= max) return s;
    return '${s.substring(0, max)}\n[… cut to fit the context budget]';
  }

  /// [v] cut to [maxText] characters, with `<sheet_data>` tags in it
  /// defused (cell text is untrusted, CQ-31).
  static String _short(Object? v) {
    final s = v == null ? '' : '$v';
    return UntrustedText.escape(
      s.length <= maxText ? s : '${s.substring(0, maxText)}…',
      'sheet_data',
    );
  }

  /// A stable 31-bit hash (FNV-1a) of [s].
  static int stableHash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  /// The context of [wb] titled [title]; [activeSheet] (name) first.
  static SheetsAiContext build(
    HeadlessWorkbook wb, {
    required String title,
    String? activeSheet,
  }) {
    final summary = _cut(spreadsheetSummary(wb, title: title), summaryTokens);
    final profiles = _cut(
      sheetProfiles(wb, activeSheet: activeSheet),
      profileTokens,
    );
    return SheetsAiContext(
      summary: summary,
      profiles: profiles,
      fingerprint: stableHash('$summary\n$profiles'),
    );
  }

  /// Title, locale, time zone, sheets, named ranges, charts and pivots.
  static String spreadsheetSummary(
    HeadlessWorkbook wb, {
    required String title,
  }) {
    final info = SheetsReadModel.spreadsheetInfo(wb);
    final b = StringBuffer()
      ..writeln('<spreadsheet>')
      ..writeln('<sheet_data>')
      ..writeln('Title: ${_short(title)}')
      ..writeln(
        'Locale: ${info['locale']} (dates and numbers display in this '
        'locale; formulas in tool calls use English syntax)',
      )
      ..writeln('Time zone: ${info['time_zone']}')
      ..writeln('Sheets:');
    for (final s in (info['sheets'] as List).cast<Map<String, Object?>>()) {
      final frozen = (s['frozen'] as Map)['rows'];
      b.writeln(
        '- "${_short(s['name'])}"${s['hidden'] == true ? ' (hidden)' : ''}'
        '${s['kind'] == 'chart' ? ' (chart sheet)' : ''}: '
        'used range ${s['used_range'] ?? 'empty'}, grid '
        '${(s['grid'] as Map)['rows']}×${(s['grid'] as Map)['columns']}'
        '${frozen != 0 ? ', $frozen frozen row(s)' : ''}'
        '${s['has_basic_filter'] == true ? ', filtered' : ''}',
      );
    }
    final names = (info['named_ranges'] as List).cast<Map<String, Object?>>();
    if (names.isNotEmpty) {
      b.writeln('Named ranges:');
      for (final n in names.take(50)) {
        b.writeln('- ${n['name']} = ${n['range'] ?? n['formula']}');
      }
    }
    final charts = (info['charts'] as List).cast<Map<String, Object?>>();
    if (charts.isNotEmpty) {
      b.writeln('Charts:');
      for (final c in charts.take(30)) {
        b.writeln(
          '- ${c['chart_id']}: ${c['type']} "${_short(c['title'] ?? '')}" '
          'on "${c['sheet']}" from ${(c['data_ranges'] as List).join(', ')}',
        );
      }
    }
    final pivots = (info['pivots'] as List).cast<Map<String, Object?>>();
    if (pivots.isNotEmpty) {
      b.writeln('Pivot tables:');
      for (final p in pivots.take(30)) {
        b.writeln(
          '- ${p['pivot_id']}: on "${p['sheet']}" at ${p['anchor']} from '
          '${p['source']}',
        );
      }
    }
    b.write('</sheet_data>\n</spreadsheet>');
    return b.toString();
  }

  /// Profiles of up to [maxSheets] sheets (active first): detected tables,
  /// column profiles and sample rows (first 3 + last 2).
  static String sheetProfiles(HeadlessWorkbook wb, {String? activeSheet}) {
    final sheets = [
      for (final s in wb.model.sheets)
        if (s.record?.kind != SheetKind.chart) s,
    ];
    final active = activeSheet == null
        ? null
        : wb.model.sheetByName(activeSheet);
    if (active != null) {
      sheets
        ..remove(active)
        ..insert(0, active);
    }
    final b = StringBuffer('<sheet_profiles>\n');
    var budget = profileTokens * charsPerToken;
    for (final s in sheets.take(maxSheets)) {
      final part = _sheetProfile(wb, s);
      if (part.length > budget) {
        b.writeln('<sheet name="${s.name}">[profile omitted: budget]</sheet>');
        continue;
      }
      budget -= part.length;
      b.writeln(part);
    }
    if (sheets.length > maxSheets) {
      b.writeln(
        '[${sheets.length - maxSheets} more sheet(s) not profiled; use '
        'sheets_describe_data]',
      );
    }
    b.write('</sheet_profiles>');
    return b.toString();
  }

  static String _sheetProfile(HeadlessWorkbook wb, SheetModel s) {
    final b = StringBuffer('<sheet name="${s.name}">\n');
    final tables = SheetsReadModel.detectTables(wb, s, max: 3);
    if (tables.isEmpty) {
      b.writeln('(empty)');
    }
    for (final t in tables) {
      final d = SheetsReadModel.describe(
        wb,
        s,
        t,
        sampleRows: 0,
        maxColumns: maxColumns,
        includeTables: false,
      );
      b.writeln(
        'Table ${d['range']}: ${d['rows']} data row(s)'
        '${d['header_row'] == null ? ', no header row' : ', header row ${d['header_row']}'}',
      );
      b.writeln('<sheet_data>');
      for (final c in (d['columns'] as List).cast<Map<String, Object?>>()) {
        b.writeln('  ${_columnLine(c)}');
      }
      if (d['columns_omitted'] != null) {
        b.writeln('  (${d['columns_omitted']} more columns)');
      }
      b.writeln('  Sample rows:');
      b.write(_sampleRows(wb, s, t, d['header_row'] != null));
      b.writeln('</sheet_data>');
    }
    b.write('</sheet>');
    return b.toString();
  }

  static String _columnLine(Map<String, Object?> c) {
    final parts = <String>[
      '${c['column']}${c['header'] == null ? '' : ' "${_short(c['header'])}"'}',
      '${c['type']}',
      '${c['non_empty']} values',
      '${c['distinct']} distinct',
    ];
    final n = c['numeric'] as Map?;
    if (n != null) {
      parts.add(
        'min ${n['min']}, max ${n['max']}, mean ${n['mean']}, sum ${n['sum']}',
      );
    }
    final d = c['date'] as Map?;
    if (d != null) parts.add('${d['min']} … ${d['max']}');
    final t = c['text'] as Map?;
    if (t != null) {
      final top = (t['top_values'] as List).cast<Map<Object?, Object?>>().take(
        5,
      );
      parts.add(
        'top: ${top.map((e) => '"${_short(e['value'])}" ×${e['count']}').join(', ')}',
      );
    }
    if (c['number_format'] != null) parts.add('format ${c['number_format']}');
    return parts.join('; ');
  }

  static String _sampleRows(
    HeadlessWorkbook wb,
    SheetModel s,
    GridRect t,
    bool header,
  ) {
    final first = header ? t.top + 1 : t.top;
    final rows = <int>[
      for (var r = first; r <= t.bottom && r < first + 3; r++) r,
      for (var r = math.max(first + 3, t.bottom - 1); r <= t.bottom; r++) r,
    ];
    final right = math.min(t.right, t.left + maxColumns - 1);
    final b = StringBuffer();
    if (header) {
      b.writeln(_csvRow(wb, s, t.top, t.left, right, label: 'header'));
    }
    var prev = -1;
    for (final r in rows) {
      if (prev >= 0 && r > prev + 1) b.writeln('…');
      b.writeln(_csvRow(wb, s, r, t.left, right, label: '${r + 1}'));
      prev = r;
    }
    return b.toString();
  }

  static String _csvRow(
    HeadlessWorkbook wb,
    SheetModel s,
    int r,
    int left,
    int right, {
    required String label,
  }) {
    final cells = [
      for (var c = left; c <= right; c++)
        _csv(_short(wb.displayAt(s.id, r, c))),
    ];
    return '$label: ${cells.join(',')}';
  }

  static String _csv(String s) =>
      s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;

  // ------------------------------------------------------------ volatile

  /// The selection block: values when ≤ [selectionValueCells] cells (CSV
  /// with row/column labels), else a profile plus the first 50 rows.
  static String selection(HeadlessWorkbook wb, List<String> ranges) {
    final b = StringBuffer();
    for (final a1 in ranges.take(5)) {
      ResolvedRange r;
      try {
        r = wb.model.parseA1(a1);
      } on InvalidRangeException {
        b.writeln('Selection $a1 (no longer valid)');
        continue;
      }
      final s = wb.model.sheet(r.sheetId);
      if (s == null) continue;
      var rect = r.rect;
      if (r.wholeColumns || r.wholeRows) {
        final used = s.usedRect();
        if (used == null) {
          b.writeln('Selection ${wb.model.a1Of(r)} (empty)');
          continue;
        }
        rect = GridRect(
          rect.top,
          rect.left,
          r.wholeColumns ? math.min(rect.bottom, used.bottom) : rect.bottom,
          r.wholeRows ? math.min(rect.right, used.right) : rect.right,
        );
      }
      final name = wb.model.a1Of(ResolvedRange(s.id, rect));
      if (rect.cellCount <= selectionValueCells) {
        b
          ..writeln('Selection $name:')
          ..write(_grid(wb, s, rect));
      } else {
        final d = SheetsReadModel.describe(
          wb,
          s,
          rect,
          sampleRows: 0,
          maxColumns: maxColumns,
          includeTables: false,
        );
        b.writeln(
          'Selection $name (${rect.cellCount} cells, ${d['rows']} rows):',
        );
        b.writeln('<sheet_data>');
        for (final c in (d['columns'] as List).cast<Map<String, Object?>>()) {
          b.writeln('  ${_columnLine(c)}');
        }
        b.writeln('</sheet_data>');
        b
          ..writeln('First 50 rows:')
          ..write(
            _grid(
              wb,
              s,
              GridRect(
                rect.top,
                rect.left,
                math.min(rect.bottom, rect.top + 49),
                math.min(rect.right, rect.left + maxColumns - 1),
              ),
            ),
          );
      }
    }
    return _cut(b.toString(), selectionTokens);
  }

  static String _grid(HeadlessWorkbook wb, SheetModel s, GridRect rect) {
    final b = StringBuffer('<sheet_data>\n');
    b.writeln(
      '  ,${[for (var c = rect.left; c <= rect.right; c++) ColumnLetters.fromIndex(c)].join(',')}',
    );
    for (var r = rect.top; r <= rect.bottom; r++) {
      b.writeln(
        '${r + 1},${[for (var c = rect.left; c <= rect.right; c++) _csv(_short(wb.displayAt(s.id, r, c)))].join(',')}',
      );
    }
    b.writeln('</sheet_data>');
    return b.toString();
  }

  /// The active cell: its formula, value and the headers of the columns
  /// its formula reads.
  static String? activeCell(HeadlessWorkbook wb, String? a1) {
    if (a1 == null) return null;
    ResolvedRange r;
    try {
      r = wb.model.parseA1(a1);
    } on InvalidRangeException {
      return null;
    }
    final s = wb.model.sheet(r.sheetId);
    if (s == null) return null;
    final row = r.rect.top, col = r.rect.left;
    final formula = wb.formulaAt(s.id, row, col);
    final value = _short(wb.displayAt(s.id, row, col));
    final b = StringBuffer(
      'Active cell ${wb.model.a1Of(ResolvedRange(s.id, GridRect.cell(row, col)))}: ',
    )..write('<sheet_data>${value.isEmpty ? '(empty)' : value}</sheet_data>');
    if (formula != null) {
      b.write(' = $formula');
      final v = validateFormula(formula);
      final headers = <String>{};
      for (final ref in v.references) {
        try {
          final rr = wb.model.parseA1(ref, contextSheetId: s.id);
          final rs = wb.model.sheet(rr.sheetId);
          if (rs == null) continue;
          final table = SheetsReadModel.detectTables(wb, rs).where(
            (t) => t.intersects(rr.rect),
          );
          for (final t in table) {
            if (!SheetsReadModel.looksLikeHeader(wb, rs.id, t)) continue;
            for (
              var c = math.max(rr.rect.left, t.left);
              c <= math.min(rr.rect.right, t.right);
              c++
            ) {
              headers.add(
                '${ColumnLetters.fromIndex(c)} "${_short(wb.displayAt(rs.id, t.top, c))}"',
              );
            }
          }
        } on Object {
          continue;
        }
      }
      if (headers.isNotEmpty) {
        b.write(
          ' (reads <sheet_data>${headers.take(20).join(', ')}</sheet_data>)',
        );
      }
    }
    return b.toString();
  }

  /// The "spreadsheet changed" element appended when the context changed
  /// since the previous turn of a thread (history is append-only).
  static String update(SheetsAiContext now) =>
      '<spreadsheet_changed>The spreadsheet changed since the context above '
      'was captured. Current state:\n${now.summary}\n\n${now.profiles}\n'
      '</spreadsheet_changed>';
}
