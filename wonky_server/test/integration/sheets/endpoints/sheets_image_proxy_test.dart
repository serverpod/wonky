@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/sheets/images/sheets_image_proxy.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// The Sheets image proxy (08 §10.1–10.2, CQ-59): viewers only, remote
/// images cached for 24 h.
void main() {
  withWonkyServerpod('Given a spreadsheet and the image proxy', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView sheet;
    late List<String> fetched;
    late Future<Uint8List> Function(String) original;
    const url = 'https://example.com/logo.png';

    setUp(() async {
      original = SheetsImageProxy.fetcher;
      fetched = [];
      SheetsImageProxy.clear();
      SheetsImageProxy.fetcher = (u) async {
        fetched.add(u);
        return Uint8List.fromList([fetched.length, 2, 3]);
      };
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      sheet = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'Images',
        null,
      );
    });
    tearDown(() {
      SheetsImageProxy.fetcher = original;
      SheetsImageProxy.clear();
    });

    test('when a viewer asks twice then the image is fetched once', () async {
      final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
      await TestDrive.share(endpoints, sheet, anna, vic, AccessRole.viewer);

      final first = await endpoints.sheets.fetchImage(
        vic.endpointSession,
        sheet.uuid,
        url,
      );
      final second = await endpoints.sheets.fetchImage(
        anna.endpointSession,
        sheet.uuid,
        url,
      );

      expect(first.buffer.asUint8List(), [1, 2, 3]);
      expect(second.buffer.asUint8List(), [1, 2, 3]);
      expect(fetched, [url]);
    });

    test('when the cached image is older than a day then it is fetched '
        'again', () async {
      final start = DateTime.utc(2026, 10, 1, 12);
      await withClock(
        Clock.fixed(start),
        () => endpoints.sheets.fetchImage(
          anna.endpointSession,
          sheet.uuid,
          url,
        ),
      );

      final later = await withClock(
        Clock.fixed(start.add(SheetsImageProxy.ttl)),
        () => endpoints.sheets.fetchImage(
          anna.endpointSession,
          sheet.uuid,
          url,
        ),
      );

      expect(fetched, [url, url]);
      expect(later.buffer.asUint8List().first, 2);
    });

    test('when someone without access asks then it is not found and nothing '
        'is fetched', () async {
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');

      await expectLater(
        endpoints.sheets.fetchImage(eve.endpointSession, sheet.uuid, url),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.notFound,
          ),
        ),
      );
      expect(fetched, isEmpty);
    });
  });
}
