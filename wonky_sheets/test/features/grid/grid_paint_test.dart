import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/grid/paint/grid_layer.dart';
import 'package:wonky_sheets/features/grid/viewport/grid_pass.dart';
import 'package:wonky_sheets/theme/sheets_tokens.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

class _ProbeLayer extends GridLayer {
  int paints = 0;
  final panes = <int>[];
  final signal = ValueNotifier(0);

  @override
  int get zOrder => GridZ.presence;

  @override
  Listenable get repaint => signal;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    paints++;
    panes.add(ctx.geometry.panes.length);
    ctx.forEachPane(canvas, (pane) {
      canvas.drawRect(
        pane.cellRect(0, 0),
        Paint()..color = const Color(0xFF123456),
      );
    });
  }
}

/// Matches a drawRect call with a paint of [color].
bool Function(Symbol, List<dynamic>) _drawsRect(Color color) =>
    (method, args) =>
        method == #drawRect &&
        (args[1] as Paint).color.toARGB32() == color.toARGB32();

RenderGridPass _pass(WidgetTester tester, String key) =>
    tester.renderObject<RenderGridPass>(find.byKey(ValueKey(key)));

void main() {
  late SheetsHarness s;

  setUp(() async {
    s = SheetsHarness.open();
    await s.type('A1', 'A long text that overflows into empty neighbours');
    await s.type('B2', '123456789012345');
    await s.type('C3', '=1/0');
    await s.type('D4', 'wrapped text in a narrow cell');
    await s.select('D4');
    await s.run('sheets.format.wrap', {'strategy': 'wrap'});
    await s.select('B5:C6');
    await s.run('sheets.format.fillColor', {'color': '#FFCC00'});
    await s.run('sheets.format.borders', {'preset': 'all', 'style': 'thick'});
    await s.select('E2:F3');
    await s.run('sheets.format.merge', {'mode': 'all'});
    await s.run('sheets.insert.checkbox', {
      'ranges': ['G1'],
    });
    await s.select('H1');
    await s.run('sheets.format.rotation', {'angle': 45});
    await s.run('sheets.view.freezeRows', {'count': 1});
    await s.run('sheets.view.freezeColumns', {'count': 1});
  });

  tearDown(() => s.dispose());

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('Given a formatted sheet with frozen panes ($mode) when the '
        'grid paints then fills, the selection and the headers use the '
        '$mode tokens', (tester) async {
      await pumpSheets(tester, s, dark: dark);
      final tokens = dark ? GridPaintTokens.dark : GridPaintTokens.light;

      expect(tester.takeException(), isNull);
      expect(
        _pass(tester, 'sheets.grid.content'),
        paints..something(_drawsRect(tokens.sheetBackground)),
      );
      expect(
        _pass(tester, 'sheets.grid.content'),
        paints..something(_drawsRect(const Color(0xFFFFCC00))),
      );
      expect(
        _pass(tester, 'sheets.grid.overlay'),
        paints..something(_drawsRect(tokens.headerBg)),
      );
      expect(s.editor.geometry!.panes, hasLength(4));
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('Given a plug-in layer when it is registered then the overlay '
      'pass paints it per pane and repaints on its signal', (tester) async {
    final probe = _ProbeLayer();
    s.editor.layers.add(probe);
    await pumpSheets(tester, s);
    final before = probe.paints;

    probe.signal.value++;
    await tester.pump();

    expect(before, greaterThan(0));
    expect(probe.paints, greaterThan(before));
    expect(probe.panes.last, 4);
    expect(
      _pass(tester, 'sheets.grid.overlay'),
      paints..something(_drawsRect(const Color(0xFF123456))),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Given the grid when zooming to 200 % then cells are twice as '
      'large', (tester) async {
    await pumpSheets(tester, s);
    final w100 = s.editor.geometry!.main.cellRect(2, 2).width;

    s.editor.setZoom(2);
    await tester.pump();

    expect(s.editor.geometry!.main.cellRect(2, 2).width, w100 * 2);
    await tester.pump(const Duration(seconds: 1));
  });
}
