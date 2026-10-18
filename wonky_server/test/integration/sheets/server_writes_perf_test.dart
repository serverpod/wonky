@Tags(['integration', 'slow'])
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../support/mcp_harness.dart';
import '../../support/sheets_fixtures.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod(
    'Given a spreadsheet with 20,000 written cells (ROWS × 20)',
    (
      sessionBuilder,
      endpoints,
    ) {
      late McpHarness anna;
      late String ss;

      setUp(() async {
        final a = await TestUsers.create(sessionBuilder, name: 'Anna');
        anna = await McpHarness.forUser(a);
        ss = await SheetsFixtures.create(anna, name: 'Big');
      });
      tearDown(HeadlessWorkbookProvider.clear);

      test(
        'when the write is reverted and re-applied then both run through the '
        'chunked RevLog writer in seconds',
        () async {
          final rows = int.tryParse(Platform.environment['ROWS'] ?? '') ?? 1000;
          final watch = Stopwatch()..start();
          final w = await anna.call('sheets.set_values', {
            'spreadsheet': ss,
            'range': 'A1',
            'values': [
              for (var r = 0; r < rows; r++)
                [for (var c = 0; c < 20; c++) 'v$r-$c'],
            ],
          });
          final written = watch.elapsedMilliseconds;
          watch.reset();
          final r = await anna.call('changes.revert', {
            'change_id': w['change_id'],
          });
          final reverted = watch.elapsedMilliseconds;
          watch.reset();
          await anna.call('changes.revert', {'change_id': r['change_id']});
          final redone = watch.elapsedMilliseconds;
          // ignore: avoid_print
          print(
            '${rows * 20} cells: write $written ms, revert $reverted ms, '
            'redo $redone ms',
          );

          expect(r['reverted_cells'], rows * 20);
          expect(await SheetsFixtures.read(anna, ss, 'T$rows'), [
            ['v${rows - 1}-19'],
          ]);
          // RevLog server changes are set-based SQL in chunked ops (RevLog
          // spec 05 §3.3): well under 1 ms per cell for writes, reverts and
          // redos (a 20k-cell redo took ~45 s on the old sync engine).
          expect(reverted, lessThan(rows * 20));
          expect(written, lessThan(rows * 20));
          expect(redone, lessThan(rows * 20));
        },
        timeout: const Timeout(Duration(minutes: 10)),
      );
    },
  );
}
