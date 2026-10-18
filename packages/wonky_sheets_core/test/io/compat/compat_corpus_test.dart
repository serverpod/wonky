import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/model.dart';

import '../support/io_support.dart';

/// File-compatibility corpus (Sheets 05 §22, 11 §12; CQ-61): every XLSX and
/// ODS file in `test/fixtures/compat/` is imported, recalculated by the
/// engine, and each formula's result must equal the result the file cached
/// (what Excel, LibreOffice or Google Sheets computed when saving). The
/// generated files come from `tool/compat/gen_compat_fixtures.dart`; real
/// saved files can be dropped into the folder.
void main() {
  final files =
      Directory('test/fixtures/compat')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.xlsx') || f.path.endsWith('.ods'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('Given the compat folder then it holds an XLSX and an ODS file', () {
    expect(files.where((f) => f.path.endsWith('.xlsx')), isNotEmpty);
    expect(files.where((f) => f.path.endsWith('.ods')), isNotEmpty);
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    group('Given $name', () {
      late WorkbookDocument imported;
      late WorkbookDocument computed;

      setUpAll(() {
        final bytes = Uint8List.fromList(file.readAsBytesSync());
        imported = name.endsWith('.ods')
            ? OdsImporter.import(bytes)
            : XlsxImporter.import(bytes);
        computed = irOf(importNew(imported).model);
      });

      test('when importing then every formula keeps its cached result', () {
        final formulas = [
          for (final s in imported.sheets)
            for (final (r, c, cell) in s.cells.entries)
              if (cell.formulaA1 != null) (s.name, r, c, cell),
        ];

        expect(formulas.length, greaterThanOrEqualTo(15));
        expect(
          formulas.where((f) => f.$4.value == null).map((f) => _a1(f)),
          isEmpty,
        );
      });

      test('when recalculating then every formula result equals the cached '
          'one', () {
        final mismatches = <String>[];
        for (final s in imported.sheets) {
          final out = computed.sheetByName(s.name)!;
          for (final (r, c, cell) in s.cells.entries) {
            if (cell.formulaA1 == null) continue;
            final got = out.cells.get(r, c)?.value;
            if (!_same(cell.value, got)) {
              mismatches.add(
                '${_a1((s.name, r, c, cell))} =${cell.formulaA1}: '
                'file ${cell.value}, engine $got',
              );
            }
          }
        }

        expect(mismatches, isEmpty);
      });
    });
  }
}

String _a1((String, int, int, IrCell) f) {
  final (sheet, r, c, _) = f;
  var col = '';
  for (var n = c + 1; n > 0; n = (n - 1) ~/ 26) {
    col = String.fromCharCode(65 + (n - 1) % 26) + col;
  }
  return '$sheet!$col${r + 1}';
}

/// Equal results: numbers within a relative 1e-9 (files store 15–17
/// significant digits), everything else exactly.
bool _same(IrValue? file, IrValue? engine) {
  if (file is IrNumber && engine is IrNumber) {
    final d = (file.number - engine.number).abs();
    return d <= file.number.abs() * 1e-9 + 1e-12;
  }
  return file == engine;
}
