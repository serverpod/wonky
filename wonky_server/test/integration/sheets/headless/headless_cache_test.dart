@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/platform/revlog/rev_file_state.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/mcp/sheets_mcp_support.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_rev_binding.dart';
import 'package:wonky_sheets_core/model.dart' hide ActorKind;

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/sheets_rev_device.dart';
import '../../../support/sheets_rev_hooks.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// The headless workbook over the RevLog file cache (RevLog spec 05 §9):
/// loaded once, it follows the file's ops, so client and server writes
/// reach it without reloads.
void main() {
  withWonkyServerpod('Given a cached headless workbook', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late String ss;
    late UuidValue space;

    SheetsRevHooks.install();

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        sheets: {
          'Data': [
            ['a', 1],
          ],
        },
      );
      final (item, _) = await SheetsMcp.resolveItem(
        anna.session,
        mcp.ctx,
        ss,
        min: Role.viewer,
      );
      space = item.contentRef!;
      // Warm the cache.
      await SheetsFixtures.read(mcp, ss, 'Data!A1');
    });
    tearDown(() {
      HeadlessWorkbookProvider.clear();
      HeadlessWorkbookProvider.budgetBytes = 2048 * 1024 * 1024;
    });

    test(
      'when a client writes through its connection then the next read sees '
      'it without a reload',
      () async {
        final loads = HeadlessWorkbookProvider.loads;
        final device = await SheetsRevDevice.open(anna, space);
        try {
          final sheet = device.model.sheetByName('Data')!;
          await device.apply(
            SetCellInputs(
              sheetId: sheet.id,
              row: 0,
              col: 0,
              inputs: [
                [CellInput.user('from a client')],
              ],
            ),
          );
        } finally {
          await device.close();
        }
        expect(await SheetsFixtures.read(mcp, ss, 'Data!A1'), [
          ['from a client'],
        ]);
        expect(HeadlessWorkbookProvider.loads, loads);
      },
    );

    test('when the instance writes itself then no reload is needed', () async {
      final loads = HeadlessWorkbookProvider.loads;
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!A1',
        'values': [
          ['tool'],
        ],
      });
      expect(await SheetsFixtures.read(mcp, ss, 'Data!A1'), [
        ['tool'],
      ]);
      expect(HeadlessWorkbookProvider.loads, loads);
    });

    test('when another instance commits and this one never hears of it then '
        'the next open catches up from the op log without a reload '
        '(CQ-59)', () async {
      final loads = HeadlessWorkbookProvider.loads;
      // The cached model keeps its file state; the write below commits
      // through a new one ("another instance"), whose bus messages and
      // listeners the old state never sees.
      RevFileStates.evict(space);
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!A1',
        'values': [
          ['elsewhere'],
        ],
      });
      final cached = HeadlessWorkbookProvider.peek(space)!;
      final sheet = cached.model.sheetByName('Data')!.id;
      expect(cached.displayAt(sheet, 0, 0), 'a');

      final opened = await HeadlessWorkbookProvider.open(anna.session, space);

      expect(identical(opened, cached), isTrue);
      expect(opened.displayAt(sheet, 0, 0), 'elsewhere');
      expect(HeadlessWorkbookProvider.loads, loads);
    });

    test('when a revert deletes cells then the model drops them', () async {
      final w = await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!C3',
        'values': [
          ['temp'],
        ],
      });
      await mcp.call('changes.revert', {'change_id': w['change_id']});
      expect(await SheetsFixtures.read(mcp, ss, 'Data!C3'), isEmpty);
    });

    test(
      'when the memory budget is exceeded then the least recently used '
      'idle entry is evicted, and a leased one never is',
      () async {
        final other = UuidValue.fromString(
          await SheetsFixtures.create(mcp, name: 'Other'),
        );
        HeadlessWorkbookProvider.clear();
        final session = sessionBuilder.build();
        final binding = SheetsRevBinding.instance;
        final first = (await HeadlessFileCache.open(session, binding, space))!;
        // Room for about one of the two models.
        HeadlessWorkbookProvider.budgetBytes =
            HeadlessWorkbookProvider.peek(space)!.estimatedBytes * 3 ~/ 2;

        // Leased: kept although over budget.
        final second = (await HeadlessFileCache.open(session, binding, other))!;
        expect(HeadlessWorkbookProvider.peek(space), isNotNull);

        // Released: the older idle entry goes.
        first.release();
        expect(HeadlessWorkbookProvider.peek(space), isNull);
        expect(HeadlessWorkbookProvider.cachedSpaces, [other]);
        second.release();
      },
    );
  });
}
