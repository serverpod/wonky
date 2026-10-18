import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_slides/config/slides_features.dart';
import 'package:wonky_slides/features/elements/chart/chart_api.dart';
import 'package:wonky_slides/features/elements/chart/chart_canvas_mode.dart';
import 'package:wonky_slides/features/elements/chart/chart_insert_dialog.dart';
import 'package:wonky_slides/features/elements/chart/chart_links.dart';
import 'package:wonky_slides/features/elements/chart/chart_section.dart';
import 'package:wonky_slides/features/elements/chart/linked_charts_panel.dart';
import 'package:wonky_slides_core/charts.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;
import 'package:wonky_ui/testing.dart';

import '../../../support/deck_screen.dart';
import 'chart_fixture.dart';

/// The chart element UI (Slides 08 §4–§10; SL-32): the Chart section, the
/// link badge and Update, the insert dialog, the Linked charts panel and the
/// 3D camera controls.
void main() {
  Finder key(String k) => find.byKey(ValueKey<String>(k));

  setUp(() {
    SlidesFeatures.enabled = {...SlidesFeatures.shipped, SlidesFeature.charts};
  });
  tearDown(SlidesFeatures.reset);

  Future<(DeckScreenRig, FakeChartApi, String, String)> open(
    WidgetTester tester, {
    bool threeD = false,
    Size size = const Size(1440, 900),
    Brightness brightness = Brightness.light,
  }) async {
    final f = chartDeck(threeD: threeD);
    final r = await pumpDeckScreen(
      tester,
      fixture: f.b,
      initialSlideId: f.slide,
      size: size,
      brightness: brightness,
    );
    final api = FakeChartApi();
    SlidesChartApi.install(r.services, api);
    return (r, api, f.linked, f.static);
  }

  for (final (size, brightness) in [
    (const Size(1440, 900), Brightness.light),
    (const Size(1440, 900), Brightness.dark),
    (const Size(640, 800), Brightness.dark),
  ]) {
    testWidgets('Given a selected linked chart at ${size.width.toInt()} px '
        '(${brightness.name}) when the inspector shows the Chart section then '
        'the source, status, style mode and style editor render', (
      tester,
    ) async {
      final (r, _, linked, _) = await open(
        tester,
        size: size,
        brightness: brightness,
      );
      r.editor.selectElements([linked]);
      if (size.width < 768) r.editor.setInspectorVisible(true);
      await tester.pump();

      expect(key('slides.inspector.section.chart'), findsOneWidget);
      expect(find.byKey(ChartSectionKeys.of('source')), findsOneWidget);
      expect(
        find.textContaining('Finance 2026 › Q3 › Revenue by region'),
        findsOneWidget,
      );
      expect(find.byKey(ChartSectionKeys.of('matchTheme')), findsOneWidget);
      expect(key('slides.chart.style.group.titles'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given a linked chart whose source changed when the deck checks '
      'its links then the badge becomes Update and Update refreshes the data '
      'with a morph', (tester) async {
    final (r, api, linked, _) = await open(tester);
    r.editor.selectElements([linked]);
    await tester.pump();
    expect(find.byKey(ChartCanvasKeys.badge), findsOneWidget);

    api.snapshots[chartId] = resolved(version: 'log2.2:aaaa:43', north: 50);
    api.statuses[linked] = ChartLinkStatusData(
      elementId: linked,
      status: ChartLinkStatusCode.changed,
      newVersion: 'log2.2:aaaa:43',
      summary: 'Data changed',
    );
    await tester.runAsync(() => ChartLinks.of(r.editor).check());
    await tester.pump();
    expect(find.byKey(ChartCanvasKeys.update), findsOneWidget);

    await tester.tap(find.byKey(ChartCanvasKeys.update));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(r.editor.model.chartLinkOf(linked)!.sourceVersion, 'log2.2:aaaa:43');
    // The morph runs, then settles.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(ChartCanvasKeys.update), findsNothing);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a viewer when a linked chart is selected then no badge '
      'shows (the snapshot is all they see)', (tester) async {
    final f = chartDeck();
    final r = await pumpDeckScreen(
      tester,
      fixture: f.b,
      initialSlideId: f.slide,
      role: AccessRole.viewer,
    );
    SlidesChartApi.install(r.services, FakeChartApi());
    r.editor.selectElements([f.linked]);
    await tester.pump();
    expect(find.byKey(ChartCanvasKeys.badge), findsNothing);
    expect(tester.takeException(), isNull);
    await r.close(tester);
  });

  testWidgets('Given a 3D chart when a camera preset is picked in the section '
      'then the camera changes in one step', (tester) async {
    final (r, _, linked, _) = await open(tester, threeD: true);
    r.editor.selectElements([linked]);
    await tester.pump();
    expect(key('slides.chart.section.rotation.20.0'), findsOneWidget);
    await r.run('slides.chart.setCamera', {'preset': 'side'});
    await tester.pump();
    final cam = ChartElementData.fromJson(
      r.editor.model.element(linked)!.dataJson,
    ).camera!;
    expect(cam.azimuth, 80);
    expect(key('slides.chart.section.rotation.80.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the insert dialog when a spreadsheet and a chart are '
      'picked through MCP then the chart is inserted linked', (tester) async {
    final (r, _, _, _) = await open(tester);
    r.h.drive.seed(
      name: 'Finance 2026',
      uuid: UuidValue.fromString(sheetUuid),
      kind: DriveItemKind.spreadsheet,
    );
    final before = r.editor.model.records(SlidesTables.chartLink).length;
    final done = r.services.dispatcher.invoke(
      'slides.insert.chartFromSheets',
      source: InvocationSource.menu,
      context: tester.element(find.byKey(const ValueKey('slides.canvas'))),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(ChartInsertKeys.dialog), findsOneWidget);
    final dialog = r.services.openDialogs
        .whereType<McpDescribableDialog>()
        .last;
    // My files lists the spreadsheet (Recent needs a last-opened date).
    expect(dialog.setField('tab', 'mine'), isTrue);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.byKey(ChartInsertKeys.spreadsheet(sheetUuid)), findsOneWidget);
    expect(dialog.setField('spreadsheet', sheetUuid), isTrue);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
    // Step 2: tiles with previews; the newer chart is not offered.
    expect(find.byKey(ChartInsertKeys.tile(chartId)), findsOneWidget);
    expect(find.byKey(ChartInsertKeys.tile('newer')), findsOneWidget);
    final fields = (dialog.describe()['fields']! as List)
        .cast<Map<Object?, Object?>>();
    final chart = fields.firstWhere((f) => f['id'] == 'chart');
    expect(chart['options'], [chartId, chart3dId]);
    expect(tester.takeException(), isNull);

    expect(dialog.setField('chart', chartId), isTrue);
    await tester.pump();
    expect(dialog.press('insert'), isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    final result = await tester.runAsync(() => done);
    expect(result!.isOk, isTrue, reason: result.message);
    expect(r.editor.model.records(SlidesTables.chartLink).length, before + 1);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given changed links when the Linked charts panel opens then it '
      'lists them with Update all', (tester) async {
    final (r, api, linked, _) = await open(tester);
    api.statuses[linked] = ChartLinkStatusData(
      elementId: linked,
      status: ChartLinkStatusCode.changed,
      newVersion: 'log2.2:aaaa:43',
    );
    api.snapshots[chartId] = resolved(version: 'log2.2:aaaa:43');
    await tester.runAsync(() => ChartLinks.of(r.editor).check());
    await r.run('slides.panel.linkedObjects');
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.byKey(LinkedChartsKeys.row(linked)), findsOneWidget);
    expect(find.byKey(LinkedChartsKeys.updateAll), findsOneWidget);
    await tester.tap(find.byKey(LinkedChartsKeys.updateAll));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(r.editor.model.chartLinkOf(linked)!.sourceVersion, 'log2.2:aaaa:43');
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });
}
