import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/wonky_editor_test.dart' show pumpEditor;

Map<String, Object?> _callout(String variant) => {
  'box': [
    {'id': 'b1', 'type': 'callout', 'variant': variant},
  ],
};

Finder _label(String text) => find.byWidgetPredicate(
  (w) => w is Text && w.data?.toLowerCase() == text.toLowerCase(),
);

void main() {
  testWidgets(
    'Given a callout when only its type changes then its frame is redrawn',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('First')
          ..insert('\n', _callout('info'))
          ..insert('Second')
          ..insert('\n', _callout('info')),
      );
      expect(_label('Info'), findsOneWidget);

      // Same text, same padding: no view model changes.
      h.controller.applyRemote(
        Delta()
          ..retain(5)
          ..retain(1, _callout('warning'))
          ..retain(6)
          ..retain(1, _callout('warning')),
      );
      await tester.pumpAndSettle();

      expect(_label('Info'), findsNothing);
      expect(_label('Warning'), findsOneWidget);
    },
  );

  testWidgets(
    'Given a collapsed details then the summary has as much room below it '
    'as above it',
    (tester) async {
      const box = {
        'box': [
          {'id': 'd1', 'type': 'details'},
        ],
      };
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Summary')
          ..insert('\n', {'header': 3, ...box})
          ..insert('Body')
          ..insert('\n', box)
          ..insert('After\n'),
      );
      h.controller.boxFrames.setCollapsed('d1', true);
      await tester.pumpAndSettle();

      final summary = h.controller.document.first.id;
      final frame = tester.getRect(
        find.byKey(ValueKey('write.editor.box.d1.$summary')),
      );
      final text = tester.getRect(find.text('Summary', findRichText: true));
      expect(frame.bottom - text.bottom, closeTo(text.top - frame.top, 1));
    },
  );
}
