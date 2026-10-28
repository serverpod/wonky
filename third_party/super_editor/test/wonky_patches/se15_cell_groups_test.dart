import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';

/// A [DocumentCellLayout] with placements by node id that records what it
/// wraps and paints.
class _TestCellLayout extends ChangeNotifier implements DocumentCellLayout {
  _TestCellLayout([Map<String, DocumentCellPlacement>? placements]) : _placements = placements ?? {};

  Map<String, DocumentCellPlacement> _placements;
  set placements(Map<String, DocumentCellPlacement> value) {
    _placements = value;
    notifyListeners();
  }

  final wrapped = <DocumentCellGroup>[];
  final painted = <DocumentCellGroupGeometry>[];

  @override
  DocumentCellPlacement? placementOf(String nodeId) => _placements[nodeId];

  @override
  Widget wrapGroup(BuildContext context, DocumentCellGroup group, Widget child) {
    wrapped.add(group);
    return child;
  }

  @override
  void paintGroup(Canvas canvas, Offset offset, DocumentCellGroupGeometry geometry) {
    painted.add(geometry);
  }
}

ParagraphNode _paragraph(String id, String text) => ParagraphNode(id: id, text: AttributedText(text));

/// No document padding and no component padding, so that slots and
/// components line up exactly.
final _stylesheet = defaultStylesheet.copyWith(
  documentPadding: EdgeInsets.zero,
  addRulesAfter: [
    StyleRule(BlockSelector.all, (doc, docNode) => {Styles.padding: const CascadingPadding.all(0.0)}),
  ],
);

final _readerStylesheet = readOnlyDefaultStylesheet.copyWith(
  documentPadding: EdgeInsets.zero,
  addRulesAfter: [
    StyleRule(BlockSelector.all, (doc, docNode) => {Styles.padding: const CascadingPadding.all(0.0)}),
  ],
);

const _long = 'This text is long enough to wrap onto several lines in a narrow column';

class _Harness {
  _Harness(this.editor, this.composer, this.layoutKey);

  final Editor editor;
  final MutableDocumentComposer composer;
  final GlobalKey layoutKey;

  DocumentLayout get layout => layoutKey.currentState as DocumentLayout;

  RenderDocumentCellGroup group([int index = 0]) =>
      find.byType(DocumentCellGroupView).evaluate().elementAt(index).renderObject! as RenderDocumentCellGroup;

  DocumentCellGroupGeometry geometry([int index = 0]) => group(index).geometry!;

  /// The bounds of [nodeId]'s component in document coordinates.
  Rect componentRect(String nodeId) {
    final component = layout.getComponentByNodeId(nodeId)!;
    final box = component.context.findRenderObject()! as RenderBox;
    return (box.localToGlobal(Offset.zero) - layout.getGlobalOffsetFromDocumentOffset(Offset.zero)) & box.size;
  }

  /// [nodeId]'s slot in document coordinates.
  Rect slotRect(String nodeId, [int groupIndex = 0]) {
    final groupBox = group(groupIndex);
    final groupOrigin = groupBox.localToGlobal(Offset.zero) - layout.getGlobalOffsetFromDocumentOffset(Offset.zero);
    return groupBox.slotRectOf(nodeId)!.shift(groupOrigin);
  }
}

Future<_Harness> _pumpEditor(
  WidgetTester tester, {
  required List<DocumentNode> nodes,
  required DocumentCellLayout? cellLayout,
  double width = 600,
}) async {
  final document = MutableDocument(nodes: nodes);
  final composer = MutableDocumentComposer();
  final editor = createDefaultDocumentEditor(document: document, composer: composer);
  final layoutKey = GlobalKey();
  await _pumpEditorWidget(tester, editor, layoutKey, cellLayout, width);
  return _Harness(editor, composer, layoutKey);
}

Future<void> _pumpEditorWidget(
  WidgetTester tester,
  Editor editor,
  GlobalKey layoutKey,
  DocumentCellLayout? cellLayout,
  double width,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 800,
            child: SuperEditor(
              editor: editor,
              documentLayoutKey: layoutKey,
              stylesheet: _stylesheet,
              cellLayout: cellLayout,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Cell groups (SE-15) >', () {
    group('rows >', () {
      testWidgetsOnAllPlatforms('lays out cells in columns and rows, ragged rows leave space', (tester) async {
        final cellLayout = _TestCellLayout({
          'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0, gap: 10),
          'b': const DocumentCellPlacement.rows(group: 't', row: 0, column: 1, gap: 10),
          'c': const DocumentCellPlacement.rows(group: 't', row: 0, column: 2, gap: 10),
          'd': const DocumentCellPlacement.rows(group: 't', row: 1, column: 0, gap: 10),
        });
        final harness = await _pumpEditor(
          tester,
          nodes: [
            _paragraph('above', 'Above'),
            _paragraph('a', 'A'),
            _paragraph('b', _long),
            _paragraph('c', 'C'),
            _paragraph('d', 'D'),
            _paragraph('below', 'Below'),
          ],
          cellLayout: cellLayout,
        );

        expect(find.byType(DocumentCellGroupView), findsOneWidget);
        expect(cellLayout.wrapped.last.id, 't');
        expect(cellLayout.wrapped.last.kind, DocumentCellGroupKind.rows);
        expect(cellLayout.wrapped.last.nodeIds, ['a', 'b', 'c', 'd']);

        final geometry = harness.geometry();
        expect(cellLayout.painted, isNotEmpty);
        expect(geometry.columnCount, 3);
        expect(geometry.rowCount, 2);
        const columnWidth = (600 - 2 * 10) / 3;
        expect(geometry.columnEdges, [0, columnWidth + 10, 2 * columnWidth + 20, 3 * columnWidth + 20]);

        // Every component is as wide as its column; the row is as tall as its
        // tallest cell (the long one).
        final heightA = harness.componentRect('a').height;
        final heightB = harness.componentRect('b').height;
        expect(heightB, greaterThan(heightA * 2));
        for (final id in ['a', 'b', 'c', 'd']) {
          expect(harness.componentRect(id).width, moreOrLessEquals(columnWidth));
        }
        expect(geometry.rowEdges, [0, heightB + 10, heightB + 10 + harness.componentRect('d').height]);
        expect(geometry.rowBottoms, [heightB, geometry.rowEdges.last]);
        expect(geometry.slotRects['a'], Rect.fromLTWH(0, 0, columnWidth, heightB));
        expect(geometry.slotRects['c'], Rect.fromLTWH(2 * columnWidth + 20, 0, columnWidth, heightB));
        expect(geometry.slotRects['d'], Rect.fromLTWH(0, heightB + 10, columnWidth, harness.componentRect('d').height));
        expect(geometry.slotRects.length, 4);
        expect(geometry.size, Size(600, geometry.rowEdges.last));

        // Components sit at their slots' top-left; the paragraphs around the
        // group stay in the column.
        expect(harness.componentRect('b').topLeft, harness.slotRect('b').topLeft);
        expect(harness.componentRect('d').topLeft, harness.slotRect('d').topLeft);
        expect(harness.componentRect('above').width, 600);
        expect(harness.componentRect('a').top, harness.componentRect('above').bottom);
        expect(harness.componentRect('below').top, moreOrLessEquals(harness.slotRect('d').bottom));
      });

      testWidgetsOnAllPlatforms('keeps columns at their minimum width without throwing', (tester) async {
        final cellLayout = _TestCellLayout({
          for (int c = 0; c < 3; c++)
            'c$c': DocumentCellPlacement.rows(group: 't', row: 0, column: c, minColumnWidth: 300),
        });
        final harness = await _pumpEditor(
          tester,
          nodes: [for (int c = 0; c < 3; c++) _paragraph('c$c', 'Cell $c')],
          cellLayout: cellLayout,
        );

        expect(tester.takeException(), isNull);
        expect(harness.geometry().columnEdges, [0, 300, 600, 900]);
        expect(harness.componentRect('c2').width, 300);
        expect(harness.group().size.width, 600);
      });

      testWidgetsOnAllPlatforms('adds spaceBefore above a row, outside the row', (tester) async {
        final cellLayout = _TestCellLayout({
          'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0),
          'b': const DocumentCellPlacement.rows(group: 't', row: 0, column: 1),
          'c': const DocumentCellPlacement.rows(group: 't', row: 1, column: 0, spaceBefore: 20),
          'd': const DocumentCellPlacement.rows(group: 't', row: 1, column: 1, spaceBefore: 50),
        });
        final harness = await _pumpEditor(
          tester,
          nodes: [
            for (final id in ['a', 'b', 'c', 'd']) _paragraph(id, id.toUpperCase())
          ],
          cellLayout: cellLayout,
        );

        final geometry = harness.geometry();
        final rowHeight = harness.componentRect('a').height;
        expect(geometry.rowBottoms.first, rowHeight);
        expect(geometry.rowEdges[1], rowHeight + 50);
        expect(geometry.slotRects['c']!.top, rowHeight + 50);
        expect(geometry.slotRects['c']!.height, rowHeight);
        expect(harness.componentRect('d').top, rowHeight + 50);
        expect(geometry.size.height, 2 * rowHeight + 50);
      });
    });

    group('right to left >', () {
      testWidgetsOnAllPlatforms('puts column 0 on the right and resolves points there', (tester) async {
        const rtl = TextDirection.rtl;
        final harness = await _pumpEditor(
          tester,
          nodes: [
            for (final id in ['a', 'b', 'c', 'd']) _paragraph(id, id.toUpperCase())
          ],
          cellLayout: _TestCellLayout({
            'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0, gap: 10, textDirection: rtl),
            'b': const DocumentCellPlacement.rows(group: 't', row: 0, column: 1, gap: 10, textDirection: rtl),
            'c': const DocumentCellPlacement.rows(group: 't', row: 0, column: 2, gap: 10, textDirection: rtl),
            'd': const DocumentCellPlacement.rows(group: 't', row: 1, column: 0, gap: 10, textDirection: rtl),
          }),
        );

        final geometry = harness.geometry();
        const columnWidth = (600 - 2 * 10) / 3;
        // The edges still run left to right.
        expect(geometry.columnEdges, [0, columnWidth + 10, 2 * columnWidth + 20, 3 * columnWidth + 20]);
        expect(geometry.slotRects['a']!.left, 2 * columnWidth + 20);
        expect(geometry.slotRects['b']!.left, columnWidth + 10);
        expect(geometry.slotRects['c']!.left, 0);
        expect(geometry.slotRects['d']!.left, 2 * columnWidth + 20);
        expect(harness.componentRect('a').topLeft, harness.slotRect('a').topLeft);
        expect(harness.componentRect('c').left, 0);

        // A point in the rightmost slot is in column 0.
        final layout = harness.layout;
        final right = harness.slotRect('a').centerRight - const Offset(2, 0);
        expect(layout.getDocumentPositionAtOffset(right)!.nodeId, 'a');
        expect(layout.getDocumentPositionNearestToOffset(right + const Offset(0, 1))!.nodeId, 'a');
      });

      testWidgetsOnAllPlatforms('fills a flow from the right', (tester) async {
        final harness = await _pumpEditor(
          tester,
          nodes: [for (int i = 0; i < 4; i++) _paragraph('i$i', 'Item $i')],
          cellLayout: _TestCellLayout({
            for (int i = 0; i < 4; i++)
              'i$i': DocumentCellPlacement.flow(
                group: 'g',
                index: i,
                maxColumns: 3,
                textDirection: TextDirection.rtl,
              ),
          }),
        );

        final geometry = harness.geometry();
        expect(geometry.columnEdges, [0, 200, 400, 600]);
        expect(geometry.slotRects['i0']!.left, 400);
        expect(geometry.slotRects['i1']!.left, 200);
        expect(geometry.slotRects['i2']!.left, 0);
        expect(geometry.slotRects['i3']!.left, 400);
        expect(geometry.slotRects['i3']!.top, geometry.rowEdges[1]);
      });
    });

    testWidgetsOnAllPlatforms('a group is no wider than its first component may be', (tester) async {
      // The default stylesheet's maxWidth is 640; the paragraphs are centered.
      final harness = await _pumpEditor(
        tester,
        width: 800,
        nodes: [
          _paragraph('above', 'Above'),
          _paragraph('a', 'A'),
          _paragraph('b', 'B'),
        ],
        cellLayout: _TestCellLayout({
          'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0),
          'b': const DocumentCellPlacement.rows(group: 't', row: 0, column: 1),
        }),
      );

      expect(harness.componentRect('above').width, 640);
      expect(harness.group().size.width, 640);
      expect(harness.slotRect('a').left, harness.componentRect('above').left);
      expect(harness.slotRect('b').right, harness.componentRect('above').right);
    });

    group('flow >', () {
      Map<String, DocumentCellPlacement> flowPlacements({double spaceBeforeOfFourth = 0}) => {
            for (int i = 0; i < 5; i++)
              'i$i': DocumentCellPlacement.flow(
                group: 'g',
                index: i,
                maxColumns: 3,
                spaceBefore: i == 3 ? spaceBeforeOfFourth : 0,
              ),
          };

      List<DocumentNode> flowNodes() => [for (int i = 0; i < 5; i++) _paragraph('i$i', 'Item $i')];

      testWidgetsOnAllPlatforms('fills rows in index order and drops columns when narrow', (tester) async {
        final cellLayout = _TestCellLayout(flowPlacements());
        // Document order differs from the flow order for the first two items.
        cellLayout.placements = {
          ...flowPlacements(),
          'i0': const DocumentCellPlacement.flow(group: 'g', index: 1, maxColumns: 3),
          'i1': const DocumentCellPlacement.flow(group: 'g', index: 0, maxColumns: 3),
        };
        final harness = await _pumpEditor(tester, nodes: flowNodes(), cellLayout: cellLayout);

        var geometry = harness.geometry();
        expect(geometry.columnCount, 3);
        expect(geometry.rowCount, 2);
        expect(geometry.columnEdges, [0, 200, 400, 600]);
        expect(geometry.slotRects['i1']!.topLeft, Offset.zero);
        expect(geometry.slotRects['i0']!.topLeft, const Offset(200, 0));
        expect(geometry.slotRects['i3']!.left, 0);
        expect(geometry.slotRects['i3']!.top, geometry.rowEdges[1]);

        // 400 px: three columns would be 133 px (< 160), so two.
        await _pumpEditorWidget(tester, harness.editor, harness.layoutKey, cellLayout, 400);
        geometry = harness.geometry();
        expect(geometry.columnCount, 2);
        expect(geometry.rowCount, 3);
        expect(geometry.columnEdges, [0, 200, 400]);

        // 150 px: one column.
        await _pumpEditorWidget(tester, harness.editor, harness.layoutKey, cellLayout, 150);
        geometry = harness.geometry();
        expect(geometry.columnCount, 1);
        expect(geometry.rowCount, 5);
        expect(harness.componentRect('i4').width, 150);
        expect(tester.takeException(), isNull);
      });

      testWidgetsOnAllPlatforms('adds the largest spaceBefore of a flow row above it', (tester) async {
        final cellLayout = _TestCellLayout(flowPlacements(spaceBeforeOfFourth: 30));
        final harness = await _pumpEditor(tester, nodes: flowNodes(), cellLayout: cellLayout);

        final geometry = harness.geometry();
        final rowHeight = harness.componentRect('i0').height;
        expect(geometry.rowBottoms.first, rowHeight);
        expect(geometry.rowEdges[1], rowHeight + 30);
        expect(geometry.slotRects['i4']!.top, rowHeight + 30);
      });
    });

    group('geometry queries >', () {
      Future<_Harness> pumpTwoCells(WidgetTester tester) {
        return _pumpEditor(
          tester,
          nodes: [
            _paragraph('above', 'Above'),
            _paragraph('a', 'A'),
            _paragraph('b', _long),
            _paragraph('c', 'C'),
            _paragraph('d', 'D'),
            _paragraph('below', 'Below'),
          ],
          cellLayout: _TestCellLayout({
            'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0, gap: 40),
            'b': const DocumentCellPlacement.rows(group: 't', row: 0, column: 1, gap: 40),
            'c': const DocumentCellPlacement.rows(group: 't', row: 1, column: 0, gap: 40),
            'd': const DocumentCellPlacement.rows(group: 't', row: 1, column: 1, gap: 40),
          }),
        );
      }

      testWidgetsOnAllPlatforms('positions and rects resolve inside cells', (tester) async {
        final harness = await pumpTwoCells(tester);
        final layout = harness.layout;

        final rectB = layout.getRectForPosition(const DocumentPosition(
          nodeId: 'b',
          nodePosition: TextNodePosition(offset: 0),
        ))!;
        expect(harness.slotRect('b').contains(rectB.center), isTrue);

        final atB = layout.getDocumentPositionAtOffset(rectB.center)!;
        expect(atB.nodeId, 'b');

        final rectD = layout.getRectForPosition(const DocumentPosition(
          nodeId: 'd',
          nodePosition: TextNodePosition(offset: 1),
        ))!;
        expect(layout.getDocumentPositionNearestToOffset(rectD.center)!.nodeId, 'd');
      });

      testWidgetsOnAllPlatforms('a point below a short cell\'s text resolves to that cell', (tester) async {
        final harness = await pumpTwoCells(tester);
        final layout = harness.layout;

        final textA = harness.componentRect('a');
        final slotA = harness.slotRect('a');
        expect(slotA.bottom, greaterThan(textA.bottom + 20));
        final belowText = Offset(slotA.left + 60, slotA.bottom - 5);

        final nearest = layout.getDocumentPositionNearestToOffset(belowText)!;
        expect(nearest.nodeId, 'a');
        expect((nearest.nodePosition as TextNodePosition).offset, 1);
        expect(layout.getDocumentPositionAtOffset(belowText)!.nodeId, 'a');
      });

      testWidgetsOnAllPlatforms('a point between two cells resolves to the nearer one', (tester) async {
        final harness = await pumpTwoCells(tester);
        final layout = harness.layout;

        final slotA = harness.slotRect('a');
        final slotB = harness.slotRect('b');
        expect(slotB.left - slotA.right, moreOrLessEquals(40));
        final y = slotA.top + 5;

        expect(layout.getDocumentPositionNearestToOffset(Offset(slotA.right + 10, y))!.nodeId, 'a');
        expect(layout.getDocumentPositionNearestToOffset(Offset(slotB.left - 10, y))!.nodeId, 'b');

        // Between the rows, under the second column.
        final slotD = harness.slotRect('d');
        expect(layout.getDocumentPositionNearestToOffset(Offset(slotD.left + 5, slotD.top - 2))!.nodeId, 'd');
      });

      testWidgetsOnAllPlatforms('a region from a later cell of a row selects from that cell', (tester) async {
        final harness = await pumpTwoCells(tester);
        final layout = harness.layout;

        final inB = harness.componentRect('b').topLeft + const Offset(4, 4);
        final inC = harness.componentRect('c').topLeft + const Offset(4, 4);
        final inD = harness.componentRect('d').topLeft + const Offset(4, 4);
        final inAbove = harness.componentRect('above').topLeft + const Offset(4, 4);
        final inBelow = harness.componentRect('below').topLeft + const Offset(4, 4);

        // Down from the second cell of the first row to the first cell of the
        // second row.
        var selection = layout.getDocumentSelectionInRegion(inB, inC)!;
        expect(selection.base.nodeId, 'b');
        expect(selection.extent.nodeId, 'c');

        // Up.
        selection = layout.getDocumentSelectionInRegion(inD, inB)!;
        expect(selection.base.nodeId, 'd');
        expect(selection.extent.nodeId, 'b');

        // Within a row, right to left.
        selection = layout.getDocumentSelectionInRegion(inD, inC)!;
        expect(selection.base.nodeId, 'd');
        expect(selection.extent.nodeId, 'c');

        // From outside the group into it, and out of it.
        selection = layout.getDocumentSelectionInRegion(inAbove, inB)!;
        expect(selection.base.nodeId, 'above');
        expect(selection.extent.nodeId, 'b');
        selection = layout.getDocumentSelectionInRegion(inB, inBelow)!;
        expect(selection.base.nodeId, 'b');
        expect(selection.extent.nodeId, 'below');
        selection = layout.getDocumentSelectionInRegion(inAbove, inBelow)!;
        expect(selection.base.nodeId, 'above');
        expect(selection.extent.nodeId, 'below');
      });

      testWidgetsOnMac('a mouse drag across the cells of a row selects them', (tester) async {
        final harness = await pumpTwoCells(tester);
        final layout = harness.layout;

        final start = layout.getGlobalOffsetFromDocumentOffset(harness.componentRect('b').topLeft + const Offset(4, 4));
        final end = layout.getGlobalOffsetFromDocumentOffset(harness.componentRect('d').topLeft + const Offset(4, 4));
        final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
        await tester.pump();
        for (int i = 1; i <= 5; i++) {
          await gesture.moveTo(Offset.lerp(start, end, i / 5)!);
          await tester.pump();
        }
        await gesture.up();
        await tester.pump(kDoubleTapTimeout);

        final selection = harness.composer.selection!;
        expect(selection.base.nodeId, 'b');
        expect(selection.extent.nodeId, 'd');
      });
    });

    testWidgetsOnAllPlatforms('regroups when the cell layout notifies', (tester) async {
      final cellLayout = _TestCellLayout();
      final harness = await _pumpEditor(
        tester,
        nodes: [_paragraph('a', 'A'), _paragraph('b', 'B'), _paragraph('p', 'P'), _paragraph('c', 'C')],
        cellLayout: cellLayout,
      );
      expect(find.byType(DocumentCellGroupView), findsNothing);
      expect(harness.componentRect('b').top, harness.componentRect('a').bottom);

      cellLayout.placements = {
        'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0),
        'b': const DocumentCellPlacement.rows(group: 't', row: 0, column: 1),
      };
      await tester.pump();
      expect(find.byType(DocumentCellGroupView), findsOneWidget);
      expect(harness.componentRect('b').top, harness.componentRect('a').top);
      expect(harness.componentRect('b').left, 300);
      // Components keep working after moving into the group.
      expect(harness.layout.getDocumentPositionAtOffset(harness.componentRect('b').center)!.nodeId, 'b');

      // A placement change moves the cell.
      cellLayout.placements = {
        'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0),
        'b': const DocumentCellPlacement.rows(group: 't', row: 1, column: 0),
      };
      await tester.pump();
      expect(harness.componentRect('b').left, 0);
      expect(harness.componentRect('b').top, harness.componentRect('a').bottom);

      // Runs with the same id that aren't consecutive are separate groups.
      cellLayout.placements = {
        'a': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0),
        'b': const DocumentCellPlacement.rows(group: 't', row: 0, column: 1),
        'c': const DocumentCellPlacement.rows(group: 't', row: 0, column: 0),
      };
      await tester.pump();
      expect(find.byType(DocumentCellGroupView), findsNWidgets(2));
      expect(harness.group(1).group.nodeIds, ['c']);
      expect(tester.takeException(), isNull);
    });

    testWidgetsOnAllPlatforms('SuperReader lays out cell groups', (tester) async {
      final document = MutableDocument(nodes: [_paragraph('a', 'A'), _paragraph('b', 'B'), _paragraph('p', 'P')]);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(document: document, composer: composer);
      final layoutKey = GlobalKey();
      final cellLayout = _TestCellLayout({
        'a': const DocumentCellPlacement.flow(group: 'g', index: 0, maxColumns: 2),
        'b': const DocumentCellPlacement.flow(group: 'g', index: 1, maxColumns: 2),
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 600,
                height: 800,
                child: SuperReader(
                  editor: editor,
                  documentLayoutKey: layoutKey,
                  stylesheet: _readerStylesheet,
                  cellLayout: cellLayout,
                ),
              ),
            ),
          ),
        ),
      );

      final harness = _Harness(editor, composer, layoutKey);
      expect(find.byType(DocumentCellGroupView), findsOneWidget);
      expect(cellLayout.painted, isNotEmpty);
      expect(harness.componentRect('b').top, harness.componentRect('a').top);
      expect(harness.componentRect('b').left, 300);
      expect(harness.componentRect('p').top, harness.componentRect('a').bottom);
      expect(harness.layout.getDocumentPositionNearestToOffset(harness.componentRect('b').center)!.nodeId, 'b');
    });
  });
}
