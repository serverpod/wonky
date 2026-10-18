import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/editor/layers/editor_layers.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write/features/editor/view/editor_view_state.dart';

import '../support/editor_harness.dart';

/// 300 paragraphs "Line n with a match".
Delta _lines() {
  final d = Delta();
  for (var i = 0; i < 300; i++) {
    d.insert('Line $i with a match\n');
  }
  return d;
}

void main() {
  testWidgets('Given find matches in every block of a long document when '
      'the layer lays out then only the matches near the viewport are '
      'measured, and scrolling measures the ones that come into view '
      '(W-13)', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = EditorHarness(_lines());
    addTearDown(h.dispose);
    h.controller.view.layout = LayoutMode.pageless;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WonkyEditor(controller: h.controller, scrollController: scroll),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final text = h.plainText;
    final matches = <HighlightRange>[];
    for (
      var i = text.indexOf('match');
      i >= 0;
      i = text.indexOf('match', i + 1)
    ) {
      matches.add(HighlightRange(i, i + 5));
    }

    h.controller.view.setFindMatches(matches);
    await tester.pump();
    final first = WonkyHighlightLayerBuilder.debugMeasuredFindMatches;
    WonkyHighlightLayerBuilder.debugMeasuredFindMatches = -1;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    final afterScroll = WonkyHighlightLayerBuilder.debugMeasuredFindMatches;

    expect(matches, hasLength(300));
    expect(first, inInclusiveRange(1, 150));
    expect(afterScroll, inInclusiveRange(1, 150));
  });
}
