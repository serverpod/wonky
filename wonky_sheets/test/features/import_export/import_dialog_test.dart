import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets/features/import/import_dialog.dart';
import 'package:wonky_sheets/features/import/import_pipeline.dart';
import 'package:wonky_sheets_core/model.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

void main() {
  late SheetsHarness s;

  setUp(() => s = SheetsHarness.open());
  tearDown(() => s.dispose());

  Future<Future<ImportDialogResult?>> open(
    WidgetTester tester, {
    bool dark = false,
    Size size = const Size(1200, 900),
  }) async {
    late BuildContext ctx;
    await pumpSheets(
      tester,
      s,
      dark: dark,
      size: size,
      child: Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox.expand();
        },
      ),
    );
    final result = showImportDialog(
      ctx,
      file: ImportFileData(
        name: 'orders.csv',
        bytes: Uint8List.fromList(utf8.encode('a;b\n1;2\n3;4\n')),
      ),
      canEdit: true,
      spreadsheetLocale: 'en_US',
      activeCell: 'B4',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    return result;
  }

  for (final dark in [false, true]) {
    testWidgets('Given a CSV file in the ${dark ? 'dark' : 'light'} import '
        'dialog when it is analyzed then the detected separator and the '
        'preview are shown', (tester) async {
      await open(tester, dark: dark);

      expect(
        find.byKey(const ValueKey('dialog.import.preview')),
        findsOneWidget,
      );
      final d = s.services.openDialogs.whereType<McpDescribableDialog>().last;
      final fields = (d.describe()['fields']! as List)
          .cast<Map<Object?, Object?>>();
      final sep = fields.firstWhere((f) => f['id'] == 'separator');
      expect(sep['detected'], ';');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Given the import dialog when MCP picks a location and presses '
      'import then the options are returned', (tester) async {
    final result = await open(tester);
    final d = s.services.openDialogs.whereType<McpDescribableDialog>().last;

    expect(d.setField('location', 'replaceAtCell'), isTrue);
    await tester.pump();
    expect(d.press('import'), isTrue);
    await tester.pump(const Duration(milliseconds: 300));

    final r = await result;
    expect(r!.options.location, ImportLocation.replaceAtCell);
    expect(r.options.cell, 'B4');
    expect(r.parsed, isNotNull);
  });

  testWidgets('Given a narrow window when the import dialog opens then it '
      'does not overflow', (tester) async {
    await open(tester, size: const Size(380, 800));

    expect(tester.takeException(), isNull);
  });
}
