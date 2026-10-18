@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope, SheetsTools;
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// One tool call of the matrix.
typedef _Case = ({
  String tool,
  Map<String, Object?> Function(String ss) args,
  Set<String?> allowed,
});

const _all = {'owner', 'editor', 'commenter', 'viewer'};
const _editors = {'owner', 'editor'};

final List<_Case> _cases = [
  (
    tool: 'sheets.get_spreadsheet',
    args: (s) => {'spreadsheet': s},
    allowed: _all,
  ),
  (
    tool: 'sheets.get_values',
    args: (s) => {
      'spreadsheet': s,
      'ranges': ['Data!A1:B2'],
    },
    allowed: _all,
  ),
  (
    tool: 'sheets.describe_data',
    args: (s) => {'spreadsheet': s},
    allowed: _all,
  ),
  (
    tool: 'sheets.find',
    args: (s) => {'spreadsheet': s, 'query': 'North'},
    allowed: _all,
  ),
  (
    tool: 'sheets.set_values',
    args: (s) => {
      'spreadsheet': s,
      'range': 'Data!F1',
      'values': [
        ['x'],
      ],
    },
    allowed: _editors,
  ),
  (
    tool: 'sheets.format_range',
    args: (s) => {
      'spreadsheet': s,
      'ranges': ['Data!A1'],
      'format': {'bold': true},
    },
    allowed: _editors,
  ),
  (
    tool: 'sheets.add_sheet',
    args: (s) => {'spreadsheet': s, 'name': 'New'},
    allowed: _editors,
  ),
  (
    tool: 'sheets.delete_rows',
    args: (s) => {'spreadsheet': s, 'sheet': 'Data', 'start': 7},
    allowed: _editors,
  ),
  (
    tool: 'sheets.create_chart',
    args: (s) => {
      'spreadsheet': s,
      'data_ranges': ['Data!A1:C7'],
    },
    allowed: _editors,
  ),
];

void main() {
  withWonkyServerpod('Given a shared spreadsheet', (sessionBuilder, endpoints) {
    tearDown(HeadlessWorkbookProvider.clear);

    for (final c in _cases) {
      for (final role in [..._all, null]) {
        final allowed = c.allowed.contains(role);
        test(
          'when ${role ?? 'a user without access'} calls ${c.tool} then it '
          '${allowed ? 'succeeds' : 'is refused'}',
          () async {
            final owner = await TestUsers.create(sessionBuilder, name: 'Own');
            final ownerMcp = await McpHarness.forUser(owner);
            final ss = await SheetsFixtures.create(
              ownerMcp,
              sheets: {'Data': SheetsFixtures.sales},
            );
            var caller = ownerMcp;
            if (role != 'owner') {
              final u = await TestUsers.create(sessionBuilder, name: 'Caller');
              if (role != null) {
                await SheetsFixtures.share(ownerMcp, ss, u.email, role);
              }
              caller = await McpHarness.forUser(u);
            }
            if (allowed) {
              await caller.call(c.tool, c.args(ss));
            } else {
              final e = await caller.error(c.tool, c.args(ss));
              expect(
                e['code'],
                role == null ? 'not_found' : 'forbidden',
              );
            }
          },
        );
      }
    }

    test(
      'when the token only has sheets:read then writing tools are forbidden '
      'and hidden from the catalog',
      () async {
        final u = await TestUsers.create(sessionBuilder, name: 'Reader');
        final full = await McpHarness.forUser(u);
        final ss = await SheetsFixtures.create(full);
        final read = await McpHarness.forUser(
          u,
          scopes: const [McpScope.sheetsRead],
        );
        await read.call('sheets.get_spreadsheet', {'spreadsheet': ss});
        final e = await read.error('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'A1',
          'values': [
            ['x'],
          ],
        });
        expect(e['code'], 'forbidden');
        expect(
          SheetsTools.setValues.scopes,
          {McpScope.sheetsEdit},
        );
      },
    );

    test('when the spreadsheet argument is a URL then it resolves', () async {
      final u = await TestUsers.create(sessionBuilder, name: 'Url');
      final mcp = await McpHarness.forUser(u);
      final ss = await SheetsFixtures.create(mcp, name: 'Linked');
      final r = await mcp.call('sheets.get_spreadsheet', {
        'spreadsheet': 'https://wonky.work/sheets/s/$ss?fv=1',
      });
      expect(r['name'], 'Linked');
      final missing = await mcp.error('sheets.get_spreadsheet', {
        'spreadsheet': 'not a spreadsheet',
      });
      expect(missing['code'], 'not_found');
    });
  });
}
