@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart'
    show DriveItem, RevFile, RevOp;
import 'package:wonky_server/src/platform/mcp/tool_executor.dart';
import 'package:wonky_server/src/platform/mcp/wonky_mcp_server.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_sheets_core/model.dart' show Dimension;

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a spreadsheet with a data sheet', (
    sessionBuilder,
    endpoints,
  ) {
    late McpHarness mcp;
    late String ss;

    setUp(() async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Sales',
        sheets: {'Data': SheetsFixtures.sales},
      );
    });
    tearDown(HeadlessWorkbookProvider.clear);

    test('when grouping rows collapsed then the nested group is stored '
        'collapsed, and ungrouping removes it', () async {
      final r = await mcp.call('sheets.group_dimension', {
        'spreadsheet': ss,
        'sheet': 'Data',
        'dimension': 'rows',
        'start': 2,
        'count': 3,
        'depth': 2,
        'collapsed': true,
      });
      expect(r['change_id'], isA<String>());
      expect(r['range'], 'Data!A2:Z4');
      expect(r['group_ids'], hasLength(2));
      var wb = await HeadlessWorkbookProvider.open(
        mcp.ctx.session,
        UuidValue.withValidation(ss),
      );
      var groups = wb.model.sheetByName('Data')!.groups.values.toList();
      expect(groups, hasLength(2));
      expect(groups.every((g) => g.dimension == Dimension.rows), isTrue);
      expect(groups.where((g) => g.collapsed), hasLength(1));
      // One change: reverting it removes both groups.
      await mcp.call('changes.revert', {'change_id': r['change_id']});
      wb = await HeadlessWorkbookProvider.open(
        mcp.ctx.session,
        UuidValue.withValidation(ss),
      );
      expect(wb.model.sheetByName('Data')!.groups, isEmpty);
      await mcp.call('sheets.group_dimension', {
        'spreadsheet': ss,
        'sheet': 'Data',
        'dimension': 'rows',
        'start': 2,
        'count': 3,
        'collapsed': true,
      });

      await mcp.call('sheets.group_dimension', {
        'spreadsheet': ss,
        'sheet': 'Data',
        'dimension': 'rows',
        'start': 2,
        'count': 3,
        'action': 'expand',
      });
      wb = await HeadlessWorkbookProvider.open(
        mcp.ctx.session,
        UuidValue.withValidation(ss),
      );
      groups = wb.model.sheetByName('Data')!.groups.values.toList();
      expect(groups.where((g) => g.collapsed), isEmpty);

      final e = await mcp.error('sheets.group_dimension', {
        'spreadsheet': ss,
        'sheet': 'Data',
        'dimension': 'columns',
        'start': 'B',
        'action': 'collapse',
      });
      expect(e['code'], 'not_found');
    });

    test('when a value is written then the result carries the sync version '
        "(the file revision of the call's last op)", () async {
      final r = await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!F1',
        'values': [
          ['x'],
        ],
      });
      final version = r['sync_version'];
      expect(version, isA<String>());
      final item = await DriveItem.db.findFirstRow(
        mcp.ctx.session,
        where: (t) => t.uuid.equals(UuidValue.withValidation(ss)),
      );
      final file = await RevFile.db.findFirstRow(
        mcp.ctx.session,
        where: (t) => t.fileUuid.equals(item!.contentRef!),
      );
      final op = await RevOp.db.findFirstRow(
        mcp.ctx.session,
        where: (t) =>
            t.fileId.equals(file!.id!) &
            t.revision.equals(int.parse(version as String)),
      );
      expect(op, isNotNull);
      expect(op!.label, contains('set_values'));
      final read = await mcp.call('sheets.get_values', {
        'spreadsheet': ss,
        'ranges': ['Data!A1'],
      });
      expect(read.containsKey('sync_version'), isFalse);
    });

    test('when an agent writes more than the per-spreadsheet limit then '
        'further writes to it are rate limited, reads and other '
        'spreadsheets are not', () async {
      final executor = ToolExecutor(
        WonkyMcpServer.executor.tools,
        targetWriteLimiter: McpRateLimiter(limit: 2),
      );
      Map<String, Object?> write(String id, String v) => {
        'spreadsheet': id,
        'range': 'Data!F1',
        'values': [
          [v],
        ],
      };
      final other = await SheetsFixtures.create(
        mcp,
        name: 'Other',
        sheets: {'Data': SheetsFixtures.sales},
      );
      expect(
        (await executor.call(
          mcp.ctx,
          'sheets.set_values',
          write(ss, 'a'),
        )).isError,
        isFalse,
      );
      expect(
        (await executor.call(
          mcp.ctx,
          'sheets.set_values',
          write('https://wonky.work/sheets/s/$ss', 'b'),
        )).isError,
        isFalse,
      );
      final third = await executor.call(
        mcp.ctx,
        'sheets.set_values',
        write(ss, 'c'),
      );
      expect(third.error?.code, 'rate_limited');
      expect(
        (await executor.call(mcp.ctx, 'sheets.get_values', {
          'spreadsheet': ss,
          'ranges': ['Data!A1'],
        })).isError,
        isFalse,
      );
      expect(
        (await executor.call(
          mcp.ctx,
          'sheets.set_values',
          write(other, 'd'),
        )).isError,
        isFalse,
      );
    });
  });
}
