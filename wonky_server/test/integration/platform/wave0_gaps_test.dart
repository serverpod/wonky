@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/mcp/mcp_config.dart';
import 'package:wonky_server/src/platform/mcp/mcp_http.dart';
import 'package:wonky_server/src/write/export/server_images.dart';

import '../../support/mcp_harness.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _throwsCode(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// The Wave 0 items that were only partly done (code-quality review):
/// CQ-2, CQ-13, CQ-14 and CQ-17.
void main() {
  withWonkyServerpod('Given Anna and Bo', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestUser bo;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
    });

    test('when a spreadsheet is registered with the id of a presentation then '
        'it is refused as a conflict (CQ-2)', () async {
      final deck = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Deck',
        null,
      );

      await expectLater(
        endpoints.drive.registerSpreadsheet(
          anna.endpointSession,
          deck.contentRef ?? deck.uuid,
          null,
          'Sheet',
        ),
        _throwsCode(WonkyErrorCode.conflict),
      );
    });

    test('when a viewer reads a cell history then it is refused, and an '
        'editor may read it (CQ-17)', () async {
      final sheet = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'Budget',
        null,
      );
      await TestDrive.share(endpoints, sheet, anna, bo, AccessRole.viewer);
      final ids = [for (var i = 0; i < 3; i++) const Uuid().v7obj()];
      Future<CellHistoryPage> read(TestUser u) => endpoints.sheets.cellHistory(
        u.endpointSession,
        sheet.uuid,
        ids[0],
        ids[1],
        ids[2],
        null,
      );

      await expectLater(read(bo), _throwsCode(WonkyErrorCode.forbidden));
      expect((await read(anna)).entries, isEmpty);
    });

    test('when an MCP request carries an invalid token then it is refused '
        'before its body is read (CQ-13)', () async {
      final handler = McpHttpHandler(
        config: McpConfig(allowedHosts: {'localhost'}),
      );
      addTearDown(handler.closeAll);
      final token = await McpHarness.forUser(anna);
      McpHttpRequest post(String secret) => McpHttpRequest(
        method: 'POST',
        headers: {'host': 'localhost', 'authorization': 'Bearer $secret'},
      );

      final refused = await handler.preauthenticate(
        anna.session,
        post('wkpat_${'x' * 40}'),
      );
      final allowed = await handler.preauthenticate(
        anna.session,
        post(token.secret),
      );

      expect(refused?.status, 401);
      expect(allowed, isNull);
    });

    test('when a user loads more remote images than the limit then the image '
        'proxy refuses the rest (CQ-14)', () async {
      for (var i = 0; i < SafeImageFetcher.fetchesPerMinute; i++) {
        await SafeImageFetcher.checkLimit(bo.id);
      }

      await expectLater(
        SafeImageFetcher.checkLimit(bo.id),
        _throwsCode(WonkyErrorCode.limitExceeded),
      );
      // Others are not affected.
      await SafeImageFetcher.checkLimit(anna.id);
    });
  });
}
