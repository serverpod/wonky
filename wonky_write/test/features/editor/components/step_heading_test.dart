import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show MarkdownFlavor;

import '../ui/wonky_editor_test.dart' show pumpEditor;

String _badge(WidgetTester tester, String nodeId) {
  final badge = find.byKey(ValueKey('write.editor.step.$nodeId'));
  return tester
      .widget<Text>(find.descendant(of: badge, matching: find.byType(Text)))
      .data!;
}

void main() {
  testWidgets(
    'Given a numbered heading when its number is set then the badge shows it at once',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Install')
          ..insert('\n', {'header': 2, 'step': 5})
          ..insert('Body\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final commands = WriteEditorCommands(h.controller);
      final id = h.controller.document.first.id;
      // The caret stays where it is: no view model changes but the step.
      await tester.placeCaretInParagraph(id, 3);
      expect(_badge(tester, id), '5');

      expect(commands.setStepNumber(7, nodeId: id), isTrue);
      await tester.pump();

      expect(_badge(tester, id), '7');
    },
  );
}
