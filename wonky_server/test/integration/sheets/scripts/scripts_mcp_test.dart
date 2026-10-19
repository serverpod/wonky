@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/scripts/script_authorizations.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'script_support.dart';

const _main = r'''
import 'package:wonky/wonky.dart';

/// Converts Celsius to Fahrenheit.
///
/// @customfunction
Object? TO_F(Object? c) => c is num ? c * 9 / 5 + 32 : null;

/// Writes the total of B2:B4 into D1.
Object? total() {
  final sheet = SpreadsheetApp.active.sheetByName('Data')!;
  final values = sheet.getRange('B2:B4').values;
  var sum = 0;
  for (final row in values) {
    sum += row[0] as int;
  }
  sheet.getRange('D1').value = sum;
  Logger.log('sum is $sum');
  return sum;
}

void boom() {
  throw StateError('nope');
}

void ask() {
  SpreadsheetApp.ui.alert('Hi');
}
''';

void main() {
  withWonkyServerpod('Given a spreadsheet and the script MCP tools', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late String ss;

    setUpAll(enableScripting);
    tearDownAll(disableScripting);

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Budget',
        sheets: {
          'Data': [
            ['Item', 'Amount'],
            ['Rent', 1000],
            ['Food', 300],
            ['Fun', 50],
          ],
        },
      );
    });
    tearDown(HeadlessWorkbookProvider.clear);

    Future<Map<String, dynamic>> save(
      String source, {
      String name = 'main.dart',
    }) => mcp.call('sheets.update_script_file', {
      'spreadsheet': ss,
      'name': name,
      'source': source,
      'create_if_missing': true,
    });

    test(
      'when a file is saved then the script builds and lists its functions',
      () async {
        final r = await save(_main);
        expect((r['build'] as Map)['status'], 'ok', reason: '$r');
        expect(r['content_hash'], hasLength(64));
        final list = await mcp.call('sheets.list_script_functions', {
          'spreadsheet': ss,
        });
        final fns = {
          for (final f in list['functions'] as List)
            (f as Map)['name']: f['kind'],
        };
        expect(fns, {
          'TO_F': 'customFunction',
          'total': 'runnable',
          'boom': 'runnable',
          'ask': 'runnable',
        });
        expect((list['build'] as Map)['status'], 'ok');
        final files = await mcp.call('sheets.get_script_files', {
          'spreadsheet': ss,
        });
        expect(((files['files'] as List).single as Map)['source'], _main);
      },
    );

    test(
      'when a broken file is saved then diagnostics come back and the last good build stays',
      () async {
        await save(_main);
        final r = await save('$_main\nextension E on int {}\n');
        final build = r['build'] as Map;
        expect(build['status'], 'errors');
        final d = (build['diagnostics'] as List).single as Map;
        expect(d['code'], 'wonky_extension');
        expect(d['line'], 29);
        final run = await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'total',
        });
        expect(run['result'], 1350);
      },
    );

    test(
      'when a function runs then it writes, logs and returns a change id that reverts',
      () async {
        await save(_main);
        final r = await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'total',
        });
        expect(r['status'], 'completed');
        expect(r['result'], 1350);
        expect(((r['logs'] as List).single as Map)['msg'], 'sum is 1350');
        expect(r['cells_written'], 1);
        expect(await SheetsFixtures.read(mcp, ss, 'Data!D1'), [
          ['1350'],
        ]);
        await mcp.call('changes.revert', {'change_id': r['change_id']});
        expect(await SheetsFixtures.read(mcp, ss, 'Data!D1'), isEmpty);
      },
    );

    test(
      'when a function fails then the error and its stack are returned and logged',
      () async {
        await save(_main);
        final r = await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'boom',
        });
        expect(r['status'], 'failed');
        final error = r['error'] as Map;
        expect(error['type'], 'StateError');
        expect(((error['frames'] as List).first as Map)['line'], 21);
        final ex = await mcp.call('sheets.get_executions', {'spreadsheet': ss});
        final first = (ex['executions'] as List).first as Map;
        expect(first['function'], 'boom');
        expect(first['status'], 'failed');
        expect(first['kind'], 'mcp');
        expect(first['runtime'], 'server');
      },
    );

    test(
      'when a server function uses the UI then it fails with UiUnavailableException',
      () async {
        await save(_main);
        final r = await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'ask',
        });
        expect((r['error'] as Map)['type'], 'UiUnavailableException');
      },
    );

    test(
      'when the script needs network access that was not authorized then MCP cannot run it',
      () async {
        await save('''
import 'package:wonky/wonky.dart';
Object? fetch() => UrlFetchApp.fetch('https://example.com').statusCode;
''');
        final e = await mcp.error('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'fetch',
        });
        expect(e['code'], 'authorization_required');
      },
    );

    test(
      'when the token lacks sheets:edit then script files cannot be edited',
      () async {
        final limited = await McpHarness.forUser(
          anna,
          scopes: ['sheets:read', 'scripts:run'],
        );
        final e = await limited.error('sheets.update_script_file', {
          'spreadsheet': ss,
          'name': 'main.dart',
          'source': _main,
          'create_if_missing': true,
        });
        expect(e['code'], 'forbidden');
      },
    );

    test('when base_hash is stale then the update conflicts', () async {
      await save(_main);
      final e = await mcp.error('sheets.update_script_file', {
        'spreadsheet': ss,
        'name': 'main.dart',
        'source': '// x',
        'base_hash': 'deadbeef',
      });
      expect(e['code'], 'conflict');
    });

    test('when a file is deleted then it is gone', () async {
      await save(_main);
      await save('void helper() {}', name: 'utils.dart');
      await mcp.call('sheets.delete_script_file', {
        'spreadsheet': ss,
        'name': 'utils.dart',
      });
      final files = await mcp.call('sheets.get_script_files', {
        'spreadsheet': ss,
      });
      expect((files['files'] as List).map((f) => (f as Map)['name']), [
        'main.dart',
      ]);
    });

    test(
      'when the endpoint compiles unchanged sources then the cached build is returned',
      () async {
        await save(_main);
        final r = await endpoints.script.compile(
          anna.endpointSession,
          uuidOf(ss),
        );
        expect(r.ok, isTrue);
        expect(r.compiled, isFalse);
        final diag = await endpoints.script.analyze(
          anna.endpointSession,
          uuidOf(ss),
          'main.dart',
          'late int x;',
        );
        expect(
          (jsonDecode(diag) as List).map((d) => (d as Map)['code']),
          contains('wonky_late'),
        );
      },
    );

    test(
      'when a client downloads the bytecode then it matches the build',
      () async {
        await save(_main);
        final bytes = await endpoints.script.bytecode(
          anna.endpointSession,
          uuidOf(ss),
        );
        expect(bytes.lengthInBytes, greaterThan(1000));
      },
    );

    test(
      'when the daily server quota is used up then runs are refused',
      () async {
        await save(_main);
        final session = anna.session;
        final u = await ScriptAuthorizations.usage(session, anna.id);
        await ScriptQuotaUsage.db.updateRow(
          session,
          u.copyWith(serverRuntimeMs: 999999999),
        );
        final r = await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'total',
        });
        expect(r['status'], 'quotaExceeded');
      },
    );
  });
}
