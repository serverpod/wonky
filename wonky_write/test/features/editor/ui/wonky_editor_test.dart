import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/editor/popovers/editor_popovers.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write/features/editor/view/editor_view_state.dart';

import '../support/editor_harness.dart';

Future<EditorHarness> pumpEditor(
  WidgetTester tester,
  Delta delta, {
  Brightness brightness = Brightness.light,
  EditorMode mode = EditorMode.editing,
  LayoutMode layout = LayoutMode.pageless,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = EditorHarness(delta, mode: mode);
  h.controller.view.layout = layout;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: WonkyEditor(controller: h.controller, documentTitle: 'Test doc'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(h.dispose);
  return h;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Given an empty document (${brightness.name}) when typing then the text appears and changes are reported',
      (tester) async {
        final h = await pumpEditor(
          tester,
          Delta()..insert('\n'),
          brightness: brightness,
        );
        await tester.placeCaretInParagraph(h.controller.document.first.id, 0);
        await tester.typeImeText('Hello');
        await tester.pump();

        expect(h.delta, Delta()..insert('Hello\n'));
        expect(h.changes, isNotEmpty);
        expect(find.text('Hello', findRichText: true), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Given a paragraph when typing /h2 and Enter then it becomes an H2 and one undo restores /h2 (AC-21.1)',
    (tester) async {
      final h = await pumpEditor(tester, Delta()..insert('\n'));
      await tester.placeCaretInParagraph(h.controller.document.first.id, 0);
      await tester.typeImeText('/h2');
      await tester.pump();
      expect(find.byKey(SlashMenu.menuKey), findsOneWidget);

      await tester.pressEnter();
      await tester.pump();

      expect(h.delta, Delta()..insert('\n', {'header': 2}));
      expect(find.byKey(SlashMenu.menuKey), findsNothing);
      final slashStep = h.changes.last;
      expect(slashStep.label, 'Heading 2');
      h.undo(slashStep);
      expect(h.delta, Delta()..insert('/h2\n'));
    },
  );

  testWidgets(
    'Given bold shortcut when pressing Mod+B over a selection then the text is bold',
    (tester) async {
      final h = await pumpEditor(tester, Delta()..insert('Hello\n'));
      await tester.placeCaretInParagraph(h.controller.document.first.id, 0);
      h.select(0, 5);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        h.delta,
        Delta()
          ..insert('Hello', {'bold': true})
          ..insert('\n'),
      );
    },
  );

  testWidgets(
    'Given a task when clicking its checkbox then it is checked as "Check item"',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Buy milk')
          ..insert('\n', {'list': 'unchecked'}),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(h.delta.operations.last.attributes, {'list': 'checked'});
      expect(h.changes.last.label, 'Check item');
    },
  );

  testWidgets(
    'Given a collaborator when their cursor is set then their name flag is shown',
    (tester) async {
      final h = await pumpEditor(tester, Delta()..insert('Shared text\n'));
      h.controller.view.setRemoteCursor(
        const RemoteCursor(
          sessionId: 's1',
          userKey: 'u1',
          name: 'Anna',
          selection: DeltaSelection.collapsed(3),
        ),
      );
      await tester.pump();
      expect(find.text('Anna'), findsOneWidget);

      h.controller.applyRemote(Delta()..insert('New '));
      await tester.pump();
      expect(
        h.controller.view.remoteCursors.single.selection,
        const DeltaSelection.collapsed(7),
      );
    },
  );

  testWidgets(
    'Given Viewing mode when the editor renders then it is read-only and typing changes nothing',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()..insert('Read me\n'),
        mode: EditorMode.viewing,
      );
      expect(find.byType(SuperReader), findsOneWidget);
      expect(find.byType(SuperEditor), findsNothing);
      expect(h.changes, isEmpty);
    },
  );

  testWidgets(
    'Given the Pages layout when rendering a long document then it is paginated',
    (tester) async {
      final delta = Delta();
      for (var i = 0; i < 80; i += 1) {
        delta.insert('Paragraph $i with some text to fill the page.\n');
      }
      final h = await pumpEditor(tester, delta, layout: LayoutMode.pages);
      await tester.pump();
      await tester.pumpAndSettle();
      final state = tester.state<WonkyEditorState>(find.byType(WonkyEditor));
      expect(state.pagination.pageCount, greaterThan(1));
      expect(h.controller.view.layout, LayoutMode.pages);
    },
  );

  testWidgets(
    'Given zoom 200 % when rendering then the text is twice as large',
    (tester) async {
      final h = await pumpEditor(tester, Delta()..insert('Zoomed\n'));
      final before = tester
          .getSize(find.text('Zoomed', findRichText: true))
          .height;
      h.controller.view.zoom = 2;
      await tester.pumpAndSettle();
      final after = tester
          .getSize(find.text('Zoomed', findRichText: true))
          .height;
      expect(after, closeTo(before * 2, before * 0.25));
    },
  );

  testWidgets('Given a caret inside a link then the link card is shown', (
    tester,
  ) async {
    final h = await pumpEditor(
      tester,
      Delta()
        ..insert('see ')
        ..insert('docs', {'link': 'https://x.dev'})
        ..insert('\n'),
    );
    await tester.placeCaretInParagraph(h.controller.document.first.id, 6);
    await tester.pump();
    expect(find.byKey(LinkHoverCard.cardKey), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
  });

  _styledLinkCardTests();
}

void _styledLinkCardTests() {
  testWidgets(
    'Given a one-character button when the caret is at its end then the link '
    'card is shown, and hidden once → moves the caret out',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Go ')
          ..insert('A', {'link': 'https://x.dev', 'linkStyle': 'button'})
          ..insert(' now\n'),
      );
      final id = h.controller.document.first.id;
      await tester.placeCaretInParagraph(id, 4);
      await tester.pump();
      expect(find.byKey(LinkHoverCard.cardKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(
        h.controller.composer.selection?.extent.nodePosition,
        const TextNodePosition(offset: 4),
      );
      expect(find.byKey(LinkHoverCard.cardKey), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
