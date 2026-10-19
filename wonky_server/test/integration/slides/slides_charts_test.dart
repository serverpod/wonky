@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart'
    hide EmbeddedObjectKind;
import 'package:wonky_server/src/platform/drive/drive_trash.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/slides/charts/slides_chart_service.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    show ChartSourceSnapshot, ChartDataSnapshot, ChartSourceVersion;

import '../../support/mcp_harness.dart';
import '../../support/sheets_fixtures.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _refused(WonkyErrorCode code, [String? reason]) => throwsA(
  isA<WonkyException>()
      .having((e) => e.code, 'code', code)
      .having(
        (e) => reason == null
            ? null
            : (jsonDecode(e.detailsJson!) as Map)['reason'],
        'reason',
        reason,
      ),
);

void main() {
  withWonkyServerpod('Given a spreadsheet with a chart', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late String ss;
    late UuidValue ssUuid;
    late String chartId;

    setUp(() async {
      SlidesChartService.reset();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Finance 2026',
        sheets: {'Data': SheetsFixtures.sales},
      );
      ssUuid = UuidValue.fromString(ss);
      final c = await mcp.call('sheets.create_chart', {
        'spreadsheet': ss,
        'data_ranges': ['Data!A1:A7', 'Data!C1:C7'],
        'type': 'column',
        'options': {'title': 'Revenue by region'},
      });
      chartId = c['chart_id'] as String;
    });
    tearDown(() {
      HeadlessWorkbookProvider.clear();
      SlidesChartService.reset();
      SlidesChartService.resolvesPerMinute = 60;
      SlidesChartService.checksPerMinute = 30;
      SlidesChartService.maxSnapshotBytes = 512 * 1024;
    });

    Future<ChartSnapshotView> resolve([TestUser? who]) =>
        endpoints.slidesCharts.resolveSnapshot(
          (who ?? anna).endpointSession,
          ssUuid,
          chartId,
        );

    Future<ChartLinkStatus> check(String version, [TestUser? who]) async =>
        (await endpoints.slidesCharts.checkLinks(
          (who ?? anna).endpointSession,
          [
            ChartLinkProbe(
              elementId: 'e1',
              spreadsheetUuid: ssUuid,
              chartObjectId: chartId,
              sourceVersion: version,
            ),
          ],
        )).single;

    test(
      'when listing the charts then each has a title, type and preview',
      () async {
        final list = await endpoints.slidesCharts.listCharts(
          anna.endpointSession,
          ssUuid,
        );
        expect(list.spreadsheetTitle, 'Finance 2026');
        expect(list.exportAllowed, isTrue);
        final c = list.charts.single;
        expect(c.chartObjectId, chartId);
        expect(c.title, 'Revenue by region');
        expect(c.type, 'column');
        expect(c.is3D, isFalse);
        expect(c.sheetName, 'Data');
        final preview = ChartSourceSnapshot.fromJson(
          jsonDecode(c.previewSnapshotJson!),
        )!;
        expect(preview.data.series.single.name, 'Revenue');
      },
    );

    test(
      'when resolving then the snapshot holds only the resolved series',
      () async {
        final v = await resolve();
        expect(v.chartObjectId, chartId);
        expect(v.sheetId, isNotNull);
        final snap = ChartDataSnapshot.fromJson(v.dataSnapshotJson);
        expect(snap.data.series.map((s) => s.name), ['Revenue']);
        expect(snap.data.series.single.values, [120, 80, 60, 200, 90, 40]);
        expect(snap.data.domain.labels.first, 'North');
        expect(snap.source.spreadsheetTitle, 'Finance 2026');
        expect(snap.source.rangesA1, ['Data!A1:A7', 'Data!C1:C7']);
        expect(snap.sourceTheme, isNotNull);
        expect(snap.version, v.sourceVersion);
        // Nothing outside the chart's ranges.
        expect(v.dataSnapshotJson, isNot(contains('Apples')));
        expect(v.dataSnapshotJson, isNot(contains('Units')));
        final token = ChartSourceVersion.tryParse(v.sourceVersion)!;
        expect(token.specHash, hasLength(16));
      },
    );

    test(
      'when resolving again without changes then the cached snapshot is used',
      () async {
        final a = await resolve();
        final n = SlidesChartService.resolves;
        final b = await resolve();
        expect(b.sourceVersion, a.sourceVersion);
        expect(SlidesChartService.resolves, n);
      },
    );

    test(
      'when nothing changed then the link is up to date without a workbook load',
      () async {
        final v = await resolve();
        HeadlessWorkbookProvider.clear();
        final loads = HeadlessWorkbookProvider.loads;
        final s = await check(v.sourceVersion);
        expect(s.status, ChartLinkState.upToDate);
        expect(s.newVersion, isNull);
        expect(HeadlessWorkbookProvider.loads, loads);
      },
    );

    test('when an unrelated cell changes then the link stays up to date with a '
        'newer token', () async {
      final v = await resolve();
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!F1',
        'values': [
          ['note'],
        ],
      });
      final s = await check(v.sourceVersion);
      expect(s.status, ChartLinkState.upToDate);
      expect(s.newVersion, isNot(v.sourceVersion));
      expect(
        ChartSourceVersion.tryParse(s.newVersion)!.sameChartAs(
          ChartSourceVersion.tryParse(v.sourceVersion)!,
        ),
        isTrue,
      );
    });

    test(
      'when a source value changes then the link is changed (data)',
      () async {
        final v = await resolve();
        await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!C2',
          'values': [
            [999],
          ],
        });
        final s = await check(v.sourceVersion);
        expect(s.status, ChartLinkState.changed);
        expect(s.summary, 'Data changed');
        final again = await resolve();
        expect(again.sourceVersion, s.newVersion);
        expect(
          ChartDataSnapshot.fromJson(
            again.dataSnapshotJson,
          ).data.series.single.values.first,
          999,
        );
      },
    );

    test(
      'when the chart style changes then the link is changed (style)',
      () async {
        final v = await resolve();
        await mcp.call('sheets.update_chart', {
          'spreadsheet': ss,
          'chart_id': chartId,
          'options': {'title': 'Renamed'},
        });
        final s = await check(v.sourceVersion);
        expect(s.status, ChartLinkState.changed);
        expect(s.summary, 'Chart style changed');
      },
    );

    test(
      'when the chart is deleted then the status says so and resolving fails',
      () async {
        final v = await resolve();
        await mcp.call('sheets.delete_chart', {
          'spreadsheet': ss,
          'chart_id': chartId,
        });
        expect(
          (await check(v.sourceVersion)).status,
          ChartLinkState.chartDeleted,
        );
        await expectLater(
          resolve(),
          _refused(WonkyErrorCode.notFound, 'chart_not_found'),
        );
      },
    );

    test('when the spreadsheet is trashed then updates are refused', () async {
      final v = await resolve();
      await DriveTrash.trash(anna.session, anna.actor, [ssUuid]);
      expect(
        (await check(v.sourceVersion)).status,
        ChartLinkState.spreadsheetTrashed,
      );
      await expectLater(
        resolve(),
        _refused(WonkyErrorCode.notFound, 'spreadsheet_trashed'),
      );
    });

    test(
      'when the spreadsheet does not exist then it counts as deleted',
      () async {
        final s = (await endpoints.slidesCharts.checkLinks(
          anna.endpointSession,
          [
            ChartLinkProbe(
              elementId: 'x',
              spreadsheetUuid: UuidValue.fromString(
                '00000000-0000-4000-8000-00000000dead',
              ),
              chartObjectId: chartId,
              sourceVersion: '',
            ),
          ],
        )).single;
        expect(s.status, ChartLinkState.spreadsheetDeleted);
      },
    );

    test(
      'when another user has no access then only a status code comes back',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final s = await check('', bo);
        expect(s.status, ChartLinkState.noAccess);
        expect(s.newVersion, isNull);
        expect(s.summary, isNull);
        await expectLater(
          resolve(bo),
          _refused(WonkyErrorCode.notFound, 'no_access'),
        );
        await expectLater(
          endpoints.slidesCharts.listCharts(bo.endpointSession, ssUuid),
          _refused(WonkyErrorCode.notFound, 'no_access'),
        );
      },
    );

    test('when a viewer may export then resolving works', () async {
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await SheetsFixtures.share(mcp, ss, bo.email, 'viewer');
      final v = await resolve(bo);
      expect(v.sourceVersion, isNotEmpty);
    });

    test('when viewers may not export then a viewer is refused', () async {
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await SheetsFixtures.share(mcp, ss, bo.email, 'viewer');
      final session = anna.session;
      final item = (await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(ssUuid),
      ))!;
      await DriveItem.db.updateRow(
        session,
        item.copyWith(nonEditorsCanExport: false),
      );
      await expectLater(
        resolve(bo),
        _refused(WonkyErrorCode.forbidden, 'export_disabled'),
      );
      expect((await check('', bo)).status, ChartLinkState.exportDisabled);
      final list = await endpoints.slidesCharts.listCharts(
        bo.endpointSession,
        ssUuid,
      );
      expect(list.exportAllowed, isFalse);
      expect(list.charts.single.previewSnapshotJson, isNull);
      // The owner still can.
      expect((await resolve()).sourceVersion, isNotEmpty);
    });

    test('when signed out then the endpoint refuses', () async {
      await expectLater(
        endpoints.slidesCharts.resolveSnapshot(
          TestUsers.unauthenticated(sessionBuilder),
          ssUuid,
          chartId,
        ),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });

    test('when resolving too often then the rate limit applies', () async {
      SlidesChartService.resolvesPerMinute = 2;
      await resolve();
      await resolve();
      await expectLater(resolve(), _refused(WonkyErrorCode.limitExceeded));
    });

    test('when checking more than 50 links then the call is refused', () async {
      await expectLater(
        endpoints.slidesCharts.checkLinks(anna.endpointSession, [
          for (var i = 0; i < 51; i++)
            ChartLinkProbe(
              elementId: 'e$i',
              spreadsheetUuid: ssUuid,
              chartObjectId: chartId,
              sourceVersion: '',
            ),
        ]),
        _refused(WonkyErrorCode.invalidArgument),
      );
    });

    test(
      'when the snapshot exceeds the size limit then it is refused',
      () async {
        SlidesChartService.maxSnapshotBytes = 64;
        await expectLater(
          resolve(),
          _refused(WonkyErrorCode.tooLarge, 'chart_too_large'),
        );
      },
    );
  });
}
