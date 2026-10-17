import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show AccessRole, PresenceJoined, PresenceRoster;
import 'package:wonky_slides/features/collab/slides_collab.dart';
import 'package:wonky_slides/features/collab/slides_presence_cursor.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides/features/editor_screen/slide_labels.dart';
import 'package:wonky_slides/features/navigator/navigator_controller.dart';
import 'package:wonky_slides/features/outline_view/outline_controller.dart';
import 'package:wonky_slides/features/outline_view/outline_view.dart';
import 'package:wonky_slides/features/text_editing/text_editing_host.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_ui/testing.dart';

import '../../harness/deck_harness.dart';
import '../../support/deck_screen.dart';
import '../../support/slides_harness.dart';
import '../collab/collab_rig.dart' show FakePresenceRepository, participant;

/// The outline view (Slides 04 §10; SL-34) in the editor screen.
void main() {
  Finder field(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

  Future<DeckScreenRig> outline(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1440, 900),
    DeckBuilder? fixture,
  }) async {
    final r = await pumpDeckScreen(
      tester,
      brightness: brightness,
      size: size,
      fixture: fixture,
    );
    await r.run('slides.view.setMode', {'mode': 'outline'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return r;
  }

  String slideAt(DeckScreenRig r, int i) => r.editor.order.entries[i].id;

  for (final brightness in Brightness.values) {
    testWidgets('Given a deck (${brightness.name}) when Outline is chosen then '
        'groups, titles and bullets show, the status bar offers it and the '
        'current slide\'s title has focus', (tester) async {
      final r = await outline(tester, brightness: brightness);

      expect(find.byKey(OutlineKeys.view), findsOneWidget);
      expect(
        find.byKey(const ValueKey('slides.status.mode.outline')),
        findsOneWidget,
      );
      final intro = r.editor.model.groups.single.id;
      expect(find.byKey(OutlineKeys.group(intro)), findsOneWidget);
      expect(find.text('Our mission'), findsOneWidget);
      expect(find.text('Make collaboration effortless'), findsOneWidget);
      expect(outlineOf(r.editor).focused, OutlineLine.title(slideAt(r, 0)));
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the outline when a title is typed then the slide title '
      'changes after a pause as one undo step per burst, and ⌘Z undoes it', (
    tester,
  ) async {
    final r = await outline(tester);
    final s = slideAt(r, 1);

    await tester.tap(field(OutlineKeys.title(s)));
    await tester.pump();
    await tester.enterText(field(OutlineKeys.title(s)), 'Our big mission');
    await tester.pump(const Duration(milliseconds: 600));
    expect(SlideLabels.title(r.editor.model, s), 'Our big mission');
    await tester.enterText(field(OutlineKeys.title(s)), 'Our big mission!');
    await tester.pump(const Duration(milliseconds: 600));

    expect(SlideLabels.title(r.editor.model, s), 'Our big mission!');
    expect(r.h.undoLabels, hasLength(1));

    await r.run('shell.edit.undo');
    await tester.pump();
    expect(SlideLabels.title(r.editor.model, s), 'Our mission');
    expect(
      tester.widget<EditableText>(field(OutlineKeys.title(s))).controller.text,
      'Our mission',
    );
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the caret in a title when Enter is pressed then a new '
      'slide follows it with the caret in its title', (tester) async {
    final r = await outline(tester);
    final s = slideAt(r, 3);
    final before = r.editor.order.length;

    await tester.tap(field(OutlineKeys.title(s)));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(r.editor.order.length, before + 1);
    final added = slideAt(r, 4);
    expect(r.editor.currentSlideId, added);
    expect(outlineOf(r.editor).focused, OutlineLine.title(added));
    await tester.enterText(field(OutlineKeys.title(added)), 'Next steps');
    await tester.pump(const Duration(milliseconds: 600));
    expect(SlideLabels.title(r.editor.model, added), 'Next steps');
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the caret in a bullet when Tab and Shift+Tab are '
      'pressed then the bullet indents and outdents', (tester) async {
    final r = await outline(tester);
    final s = slideAt(r, 1);

    await tester.tap(field(OutlineKeys.bullet(s, 0)));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump();
    expect(OutlineSlideParts.of(r.editor.model, s).bodyLines[0].level, 1);
    expect(outlineOf(r.editor).focused, OutlineLine(s, 0));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(OutlineSlideParts.of(r.editor.model, s).bodyLines[0].level, 0);
    expect(r.h.undoLabels, hasLength(2));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a group when its chevron is clicked then its slides '
      'hide in the outline and the collapse is the navigator\'s', (
    tester,
  ) async {
    final r = await outline(tester);
    final g = r.editor.model.groups.single.id;
    final inGroup = slideAt(r, 1);

    await tester.tap(find.byKey(OutlineKeys.groupChevron(g)));
    await tester.pump();

    expect(find.byKey(OutlineKeys.slide(inGroup)), findsNothing);
    expect(navigatorOf(r.editor).isCollapsed(g), isTrue);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the outline when ↓ is pressed at the end of a title '
      'then the caret moves to the first bullet', (tester) async {
    final r = await outline(tester);
    final s = slideAt(r, 1);

    await tester.tap(field(OutlineKeys.title(s)));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump();

    expect(outlineOf(r.editor).focused, OutlineLine(s, 0));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a 640 px window when the outline shows then nothing '
      'overflows', (tester) async {
    final r = await outline(tester, size: const Size(640, 780));

    expect(find.byKey(OutlineKeys.view), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a viewer when the outline shows then the lines are read '
      'only and keys do not edit', (tester) async {
    final r = await pumpDeckScreen(tester, role: AccessRole.viewer);
    await r.run('slides.view.setMode', {'mode': 'outline'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final s = slideAt(r, 1);

    final f = tester.widget<EditableText>(field(OutlineKeys.title(s)));
    expect(f.readOnly, isTrue);
    expect(
      r.services.dispatcher.stateOf('slides.outline.newSlideAfter', {
        'slideId': s,
      }).enabled,
      isFalse,
    );
    await settleTooltips(tester);
    await r.close(tester);
  });

  group('Given a collaborator editing a slide title', () {
    testWidgets('when the outline shows then a caret bar in their color '
        'marks the title', (tester) async {
      final b = DeckBuilder(title: 'Live');
      final s = b.slide(title: 'Shared');
      final repo = FakePresenceRepository();
      final d = DeckHarness.open(fixture: b, presence: repo);
      final session = PresenceSession(
        services: d.services,
        itemUuid: d.session.itemUuid,
      )..mode = 'editing';
      session.start();
      final collab = SlidesCollab.attach(d.editor);
      d.doc.attachPresence(session);
      addTearDown(d.dispose);
      d.editor.setMode(DeckViewMode.outline);
      await pumpSlides(
        tester,
        d.h,
        OutlineView(services: d.services, editor: d.editor),
      );
      repo.emit(
        PresenceRoster(
          sessionId: 'me',
          participants: [participant('me', userId: 1, name: 'Viktor')],
        ),
      );
      await tester.pump();
      final title = OutlineSlideParts.of(d.model, s).title!.id;

      repo.emit(
        PresenceJoined(
          participant: participant(
            'anna',
            cursorJson: SlidesPresenceCursor(
              slideId: s,
              editing: EditingClaim(
                kind: 'text',
                slideId: s,
                elementId: title,
                since: 1,
              ),
            ).encode(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(OutlineKeys.caretBar(title)), findsOneWidget);
      expect(find.bySemanticsLabel('Anna is editing'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      textEditingOf(d.editor).dispose();
      collab.dispose();
      session.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
