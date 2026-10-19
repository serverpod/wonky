@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a spreadsheet of Anna', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bob;
    late McpHarness mcp;
    late String ss;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bob = await TestUsers.create(sessionBuilder, name: 'Bob');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(mcp, name: 'Rules');
      await mcp.call('sheets.create_named_range', {
        'spreadsheet': ss,
        'name': 'Rate',
        'formula': '=0.19',
      });
    });
    tearDown(HeadlessWorkbookProvider.clear);

    test('when fetching its theme for Import theme then the theme JSON is '
        'returned (06 §13)', () async {
      final json = await endpoints.sheets.spreadsheetTheme(
        anna.endpointSession,
        UuidValue.fromString(ss),
      );
      final theme = jsonDecode(json) as Map<String, dynamic>;
      expect(theme['fonts'], isNotNull);
      expect(theme['colors'], isNotNull);
    });

    test('when listing its named functions then plain named formulas are '
        'not included (07 §9.4)', () async {
      final json = await endpoints.sheets.namedFunctions(
        anna.endpointSession,
        UuidValue.fromString(ss),
      );
      expect(jsonDecode(json), isEmpty);
    });

    test('when another user without access asks then it is refused', () async {
      await expectLater(
        endpoints.sheets.namedFunctions(
          bob.endpointSession,
          UuidValue.fromString(ss),
        ),
        throwsA(anything),
      );
      await expectLater(
        endpoints.sheets.spreadsheetTheme(
          bob.endpointSession,
          UuidValue.fromString(ss),
        ),
        throwsA(anything),
      );
    });
  });
}
