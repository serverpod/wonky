import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets/features/import/import_dialog.dart';
import 'package:wonky_sheets/features/import_export/pending_uploads.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

void main() {
  late SheetsHarness s;
  late MemorySheetsUploadStore store;

  setUp(() {
    s = SheetsHarness.open();
    store = MemorySheetsUploadStore();
    final q = SheetsPendingUploads(
      store: store,
      files: s.services.repositories.files,
      connectivity: s.services.connectivity,
    );
    SheetsPendingUploads.installQueue(s.services, q);
  });
  tearDown(() => s.dispose());

  Future<void> open(
    WidgetTester tester, {
    bool dark = false,
    Size? size,
  }) async {
    late BuildContext ctx;
    await pumpSheets(
      tester,
      s,
      dark: dark,
      size: size ?? const Size(1200, 900),
      child: Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox.expand();
        },
      ),
    );
    unawaited(showImportDialog(ctx, canEdit: true, spreadsheetLocale: 'en_US'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  McpDescribableDialog dialog() =>
      s.services.openDialogs.whereType<McpDescribableDialog>().last;

  for (final dark in [false, true]) {
    for (final width in [1200.0, 400.0]) {
      testWidgets('Given the import dialog (${dark ? 'dark' : 'light'}, '
          '${width.toInt()} px) when switching sources then Upload, Recent '
          'uploads and Drive render without overflow', (tester) async {
        await open(tester, dark: dark, size: Size(width, 800));

        expect(find.byKey(const ValueKey('dialog.import.browse')), findsOne);
        for (final tab in ['recent', 'drive', 'upload']) {
          expect(dialog().setField('tab', tab), isTrue);
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: tab);
        }
      });
    }
  }

  testWidgets('Given a recent import when it is picked then it becomes the '
      'file of the dialog', (tester) async {
    await store.putRecent(
      RecentImport(
        id: 'r1',
        name: 'orders.csv',
        size: 8,
        importedAt: DateTime.utc(2026, 10, 1),
      ),
      Uint8List.fromList(utf8.encode('a,b\n1,2\n')),
    );
    await open(tester);

    dialog().setField('tab', 'recent');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('dialog.import.recent.r1')), findsOne);

    await tester.tap(find.byKey(const ValueKey('dialog.import.recent.r1')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final file = dialog().describe()['file'] as Map?;
    expect(file?['name'], 'orders.csv');
  });

  testWidgets('Given no server connection when the Drive tab opens then '
      'choosing a spreadsheet is disabled', (tester) async {
    await open(tester);

    dialog().setField('tab', 'drive');
    await tester.pump(const Duration(milliseconds: 300));

    final button = find.byKey(const ValueKey('dialog.import.drivePick'));
    expect(button, findsOne);
    expect(dialog().press('chooseFromDrive'), isTrue);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dialog.pickSpreadsheet.search')),
      findsNothing,
    );
  });

  test(
    'when a file is imported twice then Recent uploads keeps one entry',
    () async {
      final q = SheetsPendingUploads.of(s.services)!;
      final bytes = Uint8List.fromList([1, 2]);

      await q.recordRecentImport('a.csv', bytes);
      await q.recordRecentImport('a.csv', bytes);
      await q.recordRecentImport('b.csv', bytes);

      expect(
        [for (final r in await q.recentImports()) r.name],
        ['b.csv', 'a.csv'],
      );
    },
  );
}
