@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given two editors of a spreadsheet', (
    sessionBuilder,
    endpoints,
  ) {
    late McpHarness anna;
    late McpHarness bo;
    late String ss;

    setUp(() async {
      final a = await TestUsers.create(sessionBuilder, name: 'Anna');
      final b = await TestUsers.create(sessionBuilder, name: 'Bo');
      anna = await McpHarness.forUser(a);
      bo = await McpHarness.forUser(b);
      ss = await SheetsFixtures.create(anna, name: 'Shared');
      await SheetsFixtures.share(anna, ss, b.email, 'editor');
    });
    tearDown(HeadlessWorkbookProvider.clear);

    test(
      'when reverting a set_values after the other edited one cell then that '
      'cell is kept and reported as skipped',
      () async {
        final w = await anna.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'A1',
          'values': [
            ['one', 'two', 'three'],
          ],
        });
        await bo.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'B1',
          'values': [
            ['bo'],
          ],
        });
        final r = await anna.call('changes.revert', {
          'change_id': w['change_id'],
        });
        expect(r['reverted_cells'], 2);
        final skipped = (r['skipped'] as List).cast<Map<String, dynamic>>();
        expect(skipped, hasLength(1));
        expect(skipped.single['a1'], 'Sheet1!B1');
        expect(skipped.single['reason'], 'changed_by_other');
        expect(await SheetsFixtures.read(anna, ss, 'A1:C1'), [
          [null, 'bo'],
        ]);
      },
    );

    test(
      'when reverting someone else\'s change then it is not found',
      () async {
        final w = await anna.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'A1',
          'values': [
            ['mine'],
          ],
        });
        final e = await bo.error('changes.revert', {
          'change_id': w['change_id'],
        });
        expect(e['code'], 'not_found');
      },
    );

    test(
      'when reverting a revert then the change is back (redo)',
      () async {
        final w = await anna.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'A1',
          'values': [
            ['x'],
          ],
        });
        final undo = await anna.call('changes.revert', {
          'change_id': w['change_id'],
        });
        await anna.call('changes.revert', {'change_id': undo['change_id']});
        expect(await SheetsFixtures.read(anna, ss, 'A1'), [
          ['x'],
        ]);
      },
    );
  });
}
