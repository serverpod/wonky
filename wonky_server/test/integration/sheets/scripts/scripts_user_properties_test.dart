@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'script_support.dart';

const _main = r'''
import 'package:wonky/wonky.dart';

Object? bump() {
  final p = PropertiesService.userProperties;
  final n = int.parse(p.getProperty('n') ?? '0') + 1;
  p.setProperty('n', '$n');
  return n;
}

Object? forget() {
  PropertiesService.userProperties.deleteProperty('n');
  return PropertiesService.userProperties.getProperty('n');
}
''';

/// `PropertiesService.userProperties` of server runs: `ScriptUserProperty`
/// rows of the run-as user (RevLog spec 02 §2.4, Sheets 09 §6.9).
void main() {
  withWonkyServerpod('Given a script that keeps a per-user counter', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late McpHarness annaMcp;
    late String ss;

    setUpAll(enableScripting);
    tearDownAll(disableScripting);

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      annaMcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        annaMcp,
        name: 'Counter',
        sheets: {
          'Data': [
            ['x'],
          ],
        },
      );
      final r = await annaMcp.call('sheets.update_script_file', {
        'spreadsheet': ss,
        'name': 'main.dart',
        'source': _main,
        'create_if_missing': true,
      });
      expect((r['build'] as Map)['status'], 'ok', reason: '$r');
    });
    tearDown(HeadlessWorkbookProvider.clear);

    Future<Object?> run(McpHarness mcp, String fn) async =>
        (await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': fn,
        }))['result'];

    Future<UuidValue> fileOf(String itemUuid) async =>
        (await DriveItem.db.findFirstRow(
          anna.session,
          where: (t) => t.uuid.equals(uuidOf(itemUuid)),
        ))!.contentRef!;

    test('when it runs twice then the value persists between runs as a '
        "row of the user's", () async {
      expect(await run(annaMcp, 'bump'), 1);
      expect(await run(annaMcp, 'bump'), 2);

      final file = await fileOf(ss);
      final rows = await ScriptUserProperty.db.find(
        sessionBuilder.build(),
        where: (t) => t.fileUuid.equals(file),
      );
      expect(rows.single.key, 'n');
      expect(rows.single.value, '2');
      expect(rows.single.userId, anna.id);
    });

    test('when the client sets a property then server runs see it, and '
        'the server writes reach the client', () async {
      final file = await fileOf(ss);
      await endpoints.sheets.setUserProperties(anna.endpointSession, file, {
        'n': '41',
      });
      expect(await run(annaMcp, 'bump'), 42);
      expect(
        await endpoints.sheets.getUserProperties(anna.endpointSession, file),
        {'n': '42'},
      );
      // Private per user.
      await SheetsFixtures.share(annaMcp, ss, bo.email, 'viewer');
      expect(
        await endpoints.sheets.getUserProperties(bo.endpointSession, file),
        isEmpty,
      );
    });

    test('when another user runs it then they get their own value', () async {
      await run(annaMcp, 'bump');
      await run(annaMcp, 'bump');
      await SheetsFixtures.share(annaMcp, ss, bo.email, 'editor');
      final boMcp = await McpHarness.forUser(bo);

      expect(await run(boMcp, 'bump'), 1);
      expect(await run(annaMcp, 'bump'), 3);
    });

    test('when the property is deleted then it is gone', () async {
      await run(annaMcp, 'bump');

      expect(await run(annaMcp, 'forget'), isNull);
      expect(await run(annaMcp, 'bump'), 1);
    });
  });
}
