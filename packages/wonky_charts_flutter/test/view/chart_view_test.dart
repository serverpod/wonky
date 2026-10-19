import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_charts/wonky_charts.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart';

import '../support.dart';

void main() {
  test('Given chart data when the rows are formatted then gaps are empty and '
      'the domain is the first column', () {
    final t = chartDataRows(twoSeries());
    expect(t.headers, ['Month', 'North', 'South']);
    expect(t.rows[1], ['Feb', '13', '']);
    expect(chartDataJson(twoSeries())['headers'], t.headers);
  });

  test('Given a hit on a point when the tooltip lines are built then the '
      'category and that series show', () {
    final lines = chartTooltipLines(
      twoSeries(),
      const ChartSpec(type: ChartType.column),
      const SceneTag(SceneRole.point, seriesKey: 'north', pointIndex: 2),
    );
    expect(lines, ['Mar', 'North: 16']);
    expect(chartTooltipApplies(const SceneTag(SceneRole.legendEntry)), isFalse);
  });

  test('Given specs when their icons are made then the variant ids follow', () {
    expect(
      ChartTypeIcon.of(const ChartSpec(type: ChartType.column)).id,
      'column',
    );
    expect(
      ChartTypeIcon.of(
        const ChartSpec(type: ChartType.bar, stacking: ChartStacking.percent),
      ).id,
      'percentBar',
    );
    expect(
      ChartTypeIcon.of(
        ChartSpec.fromJson(const {
          'v': 1,
          'type': 'pie',
          'typeOptions': {'pieHole': 0.5},
          'threeD': {'enabled': true},
        }),
      ).id,
      'doughnut3d',
    );
  });

  testWidgets('Given a ChartView with tooltips when the pointer hovers a bar '
      'then its value shows', (tester) async {
    await pumpShad(
      tester,
      SizedBox(
        width: 400,
        height: 250,
        child: ChartView(
          spec: const ChartSpec(type: ChartType.column),
          data: twoSeries(),
          theme: exportTheme(),
          tooltips: true,
          legendHighlight: true,
        ),
      ),
    );
    expect(find.byType(ChartView), findsOneWidget);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    var found = false;
    var last = Offset.zero;
    // Sweep the plot until a bar is hit.
    for (var x = 40.0; x < 380 && !found; x += 6) {
      for (var y = 60.0; y < 220 && !found; y += 10) {
        last = Offset(x, y);
        await gesture.moveTo(last);
        await tester.pump();
        found = find
            .byKey(const ValueKey<String>('charts.tooltip'))
            .evaluate()
            .isNotEmpty;
      }
    }
    expect(found, isTrue);
    expect(tester.takeException(), isNull);

    // CQ-47: moving within the bar moves the tooltip without rebuilding
    // (or repainting) the chart, which sits behind its own boundary.
    final paint = find.descendant(
      of: find.byType(ChartView),
      matching: find.byType(CustomPaint),
    );
    final before = tester.widget<CustomPaint>(paint.first);
    final at = tester.getTopLeft(
      find.byKey(const ValueKey<String>('charts.tooltip')),
    );

    await gesture.moveTo(last + const Offset(1, 1));
    await tester.pump();

    expect(identical(tester.widget<CustomPaint>(paint.first), before), isTrue);
    expect(
      find.ancestor(of: paint.first, matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('charts.tooltip'))),
      isNot(at),
    );
  });

  testWidgets('Given a 3D type icon and the data table dialog when they are '
      'shown in dark mode then they render', (tester) async {
    await pumpShad(
      tester,
      Builder(
        builder: (context) => Column(
          children: [
            const SizedBox(
              width: 48,
              height: 36,
              child: ChartTypeIcon(
                id: 'column3d',
                type: ChartType.column,
                threeD: true,
              ),
            ),
            ShadButtonProbe(
              onPressed: () => showChartDataTableDialog(
                context,
                data: twoSeries(),
                strings: const ChartDataTableStrings(
                  title: 'Data of Revenue',
                  close: 'Close',
                  noData: 'No data',
                ),
              ),
            ),
          ],
        ),
      ),
      brightness: Brightness.dark,
    );
    await tester.tap(find.byType(ShadButtonProbe));
    await tester.pumpAndSettle();
    expect(find.text('Data of Revenue'), findsOneWidget);
    expect(find.text('Feb'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class ShadButtonProbe extends StatelessWidget {
  const ShadButtonProbe({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onPressed,
    child: const SizedBox(width: 40, height: 40),
  );
}
