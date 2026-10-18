import 'package:clock/clock.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:wonky_app/wonky_app.dart' show PresenceSession;
import 'package:wonky_client/wonky_client.dart' show PresenceRoster;
import 'package:wonky_slides/features/collab/slides_collab.dart';
import 'package:wonky_slides/features/outline_view/outline_controller.dart';
import 'package:wonky_slides/features/outline_view/outline_view.dart';
import 'package:wonky_slides/features/text_editing/text_editing_host.dart';
import 'package:wonky_slides_core/testing.dart' show DeckBuilder;
import 'package:wonky_slides/features/collab/presence_widgets.dart';
import 'package:wonky_slides/features/collab/slides_presence_cursor.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyMenuItem;

import '../../harness/deck_harness.dart';
import '../../support/slides_harness.dart';
import 'collab_rig.dart';

/// Live collaboration (Slides 09 §1–§2; SL-37): live pointers, follow mode
/// refinements, released soft-lock fades, structure hints, agent flashes
/// and the Present button's live dot.
void main() {
  const session = 'AbCdEfGhIjKlMnOpQrStUv';

  group('Given a Slides presence cursor with a pointer and a surface', () {
    test('when encoded and parsed then pointer (whole su) and surface '
        'round-trip', () {
      const c = SlidesPresenceCursor(
        viewMode: 'masters',
        slideId: 's1',
        surfaceId: 'l1',
        pointer: Offset(120.4, 80.6),
      );

      final parsed = SlidesPresenceCursor.tryParse(c.encode())!;

      expect(parsed.pointer, const Offset(120, 81));
      expect(parsed.surfaceId, 'l1');
      expect(parsed.viewMode, 'masters');
    });

    test('when it has no pointer then the JSON carries pointer null', () {
      const c = SlidesPresenceCursor(slideId: 's1');

      expect(c.encode(), contains('"pointer":null'));
      expect(SlidesPresenceCursor.tryParse(c.encode())!.pointer, isNull);
    });
  });

  group('Given two users on one deck', () {
    testWidgets('when this user moves the mouse over the slide then the '
        'pointer is sent in slide units, and leaving the slide clears it', (
      tester,
    ) async {
      final r = await CollabRig.pump(tester);
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: r.at(tester, 500, 300));
      addTearDown(g.removePointer);

      await g.moveTo(r.at(tester, 600, 400));
      await tester.pump();
      final on = await r.lastSent(tester);
      expect(on.pointer!.dx, closeTo(600, 1));
      expect(on.pointer!.dy, closeTo(400, 1));

      await g.moveTo(r.at(tester, -200, -200));
      await tester.pump();
      expect((await r.lastSent(tester)).pointer, isNull);
      await r.close(tester);
    });

    testWidgets('when Anna\'s pointer is on this slide then her arrow and '
        'name show (light and dark), hide after 5 s idle, and the '
        'collaborator cursors toggle hides them', (tester) async {
      for (final brightness in Brightness.values) {
        final r = await CollabRig.pump(tester, brightness: brightness);
        await r.join(
          tester,
          CollabRig.anna,
          SlidesPresenceCursor(
            slideId: r.f.slide,
            pointer: const Offset(800, 400),
          ),
        );
        const key = ValueKey('slides.collab.pointer.anna');
        expect(find.byKey(key), findsOneWidget);
        expect(
          find.descendant(of: find.byKey(key), matching: find.text('Anna')),
          findsOneWidget,
        );
        expect(r.collab.presence.pointersOn(r.f.slide, clock.now()), [
          isA<Object>(),
        ]);

        await tester.pump(const Duration(seconds: 6));
        expect(find.byKey(key), findsNothing);

        // A move shows it again; the View toggle hides it.
        await r.move(
          tester,
          'anna',
          SlidesPresenceCursor(
            slideId: r.f.slide,
            pointer: const Offset(820, 420),
          ),
        );
        expect(find.byKey(key), findsOneWidget);
        await r.d.run('slides.view.toggleRemoteCursors');
        await tester.pump();
        expect(find.byKey(key), findsNothing);
        await r.d.run('slides.view.toggleRemoteCursors');
        await r.close(tester);
      }
    });

    testWidgets('when Anna\'s pointer is on another slide then it is not '
        'drawn here', (tester) async {
      final r = await CollabRig.pump(tester);
      await r.join(
        tester,
        CollabRig.anna,
        SlidesPresenceCursor(
          slideId: r.f.placeholders,
          pointer: const Offset(800, 400),
        ),
      );

      expect(
        find.byKey(const ValueKey('slides.collab.pointer.anna')),
        findsNothing,
      );
      await r.close(tester);
    });

    testWidgets('when Anna releases her soft lock then its outline fades '
        'over 300 ms', (tester) async {
      final r = await CollabRig.pump(tester);
      await r.join(tester, CollabRig.anna, r.cursor(editing: r.claim(r.f.box)));
      expect(
        find.byKey(ValueKey('slides.collab.lockFlag.${r.f.box}')),
        findsOneWidget,
      );

      await r.move(tester, 'anna', r.cursor());
      expect(
        find.byKey(const ValueKey('slides.collab.released')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('slides.collab.released')),
        findsNothing,
      );
      await r.close(tester);
    });

    testWidgets('when this user adds a slide then a structure hint names it', (
      tester,
    ) async {
      final r = await CollabRig.pump(tester);
      final before = r.d.editor.order.entries.map((e) => e.id).toSet();

      await r.d.run('slides.slide.new');
      await tester.pump();

      final added = r.d.editor.order.entries
          .map((e) => e.id)
          .toSet()
          .difference(before);
      final hint = r.sentHints.lastWhere((h) => h['t'] == 'structure');
      expect(hint['slideIds'], containsAll(added));
      await r.close(tester);
    });

    testWidgets('when Anna sends a structure hint then the navigator row of '
        'the slide shimmers for 1 s', (tester) async {
      final r = await CollabRig.pump(tester);
      await pumpSlides(
        tester,
        r.d.h,
        SizedBox(
          width: 200,
          height: 100,
          child: StructureShimmer(editor: r.d.editor, id: r.f.placeholders),
        ),
      );
      final key = ValueKey('slides.navigator.shimmer.${r.f.placeholders}');
      expect(find.byKey(key), findsNothing);

      await r.hints(tester, 'anna', [
        {
          't': 'structure',
          'slideIds': [r.f.placeholders],
          'groupIds': <String>[],
          'hlcMillis': 1,
        },
      ]);
      await tester.pump(const Duration(milliseconds: 100));

      expect(r.collab.hints.shimmerOf(r.f.placeholders), isNotNull);
      expect(find.byKey(key), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(key), findsNothing);
      await r.close(tester);
    });
  });

  group('Given a collaborator in another view mode', () {
    testWidgets('when following Anna in the outline then this editor '
        'switches to the outline', (tester) async {
      final r = await CollabRig.pump(tester);
      await r.join(
        tester,
        CollabRig.anna,
        SlidesPresenceCursor(viewMode: 'outline', slideId: r.f.placeholders),
      );

      await r.d.run('slides.presence.follow', {'sessionId': 'anna'});
      await tester.pump();

      expect(r.d.editor.mode, DeckViewMode.outline);
      expect(r.d.editor.currentSlideId, r.f.placeholders);
      expect(r.collab.presence.following.value, 'anna');
      await r.close(tester);
    });

    testWidgets('when Anna edits a layout then her tooltip names it, her '
        'selection shows only on that layout, and jumping opens it in '
        'masters mode', (tester) async {
      final r = await CollabRig.pump(tester);
      final layout = r.model.slide(r.f.placeholders)!.layoutId!;
      final name = r.model.layout(layout)!.name;
      await r.join(
        tester,
        CollabRig.anna,
        SlidesPresenceCursor(
          viewMode: 'masters',
          slideId: r.f.slide,
          surfaceId: layout,
        ),
      );

      expect(r.collab.presence.detailOf('anna'), 'Editing layout · $name');
      expect(r.collab.presence.cursorsOn(r.f.slide), isEmpty);
      expect(r.collab.presence.cursorsOn(layout), hasLength(1));

      await r.d.run('slides.presence.jumpTo', {'sessionId': 'anna'});
      await tester.pump();

      expect(r.d.editor.mode, DeckViewMode.masters);
      expect(r.d.editor.surfaceId, layout);
      final sent = await r.lastSent(tester);
      expect(sent.viewMode, 'masters');
      expect(sent.surfaceId, layout);
      await r.close(tester);
    });
  });

  group('Given Anna presenting with a presentation session', () {
    SlidesPresenceCursor presenting(CollabRig r) => SlidesPresenceCursor(
      route: 'present',
      slideId: r.f.placeholders,
      presenting: PresentingState(
        presentationId: session,
        slideId: r.f.placeholders,
        step: 1,
      ),
    );

    testWidgets('when following her presentation then this window opens '
        'the follower view of her session', (tester) async {
      final r = await CollabRig.pump(tester);
      await r.join(tester, CollabRig.anna, presenting(r));

      final res = await r.d.run('slides.presence.followPresenter', {
        'sessionId': 'anna',
      });

      expect(res.isOk, isTrue);
      final uri = r.d.services.router.routeInformationProvider.value.uri;
      expect(uri.path, endsWith('/present'));
      expect(uri.queryParameters, {'view': 'follow', 'session': session});
      await r.close(tester);
    });

    testWidgets('when this user follows her in the editor then the banner '
        'offers to watch the presentation', (tester) async {
      final r = await CollabRig.pump(tester);
      await r.join(tester, CollabRig.anna, presenting(r));

      await r.d.run('slides.presence.follow', {'sessionId': 'anna'});
      await tester.pump();

      expect(
        find.byKey(const ValueKey('slides.collab.followWatch')),
        findsOneWidget,
      );
      expect(find.text('Watch presentation'), findsOneWidget);
      await r.close(tester);
    });

    testWidgets('when the Present button shows then it has a live dot and '
        'the Present menu offers to follow her', (tester) async {
      final r = await CollabRig.pump(tester);
      await r.join(tester, CollabRig.anna, presenting(r));
      await pumpSlides(
        tester,
        r.d.h,
        Center(
          child: PresentLiveDot(
            services: r.d.services,
            child: const SizedBox(width: 80, height: 32),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('slides.present.liveDot')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Anna is presenting'), findsOneWidget);
      final items = followPresenterMenuItems(
        tester.element(find.byType(PresentLiveDot)),
        r.d.services,
      );
      expect(
        items.whereType<WonkyMenuItem>().single.label,
        'Follow Anna\'s '
        'presentation',
      );

      await r.move(tester, 'anna', r.cursor());
      expect(
        find.byKey(const ValueKey('slides.present.liveDot')),
        findsNothing,
      );
      await r.close(tester);
    });
  });

  group('Given the outline view with presence', () {
    testWidgets('when this user types a title then its element is claimed '
        '(forced: the outline never asks), the typing is sent as a text '
        'hint, and leaving the line releases the claim', (tester) async {
      final b = DeckBuilder(title: 'Live');
      final s = b.slide(title: 'Shared');
      final other = b.slide(title: 'Other');
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
      Finder field(Key key) => find.descendant(
        of: find.byKey(key),
        matching: find.byType(EditableText),
      );

      await tester.tap(field(OutlineKeys.title(s)));
      await tester.pump();
      await tester.enterText(field(OutlineKeys.title(s)), 'Shared idea');
      await tester.pump(const Duration(milliseconds: 150));

      final claim = collab.locks.published;
      expect(claim?.elementId, title);
      expect(claim?.forced, isTrue);
      final hints = [
        for (final u in repo.updates)
          for (final h in u.hints ?? const <String>[])
            (jsonDecode(h) as Map).cast<String, Object?>(),
      ];
      final text = hints.lastWhere((h) => h['t'] == 'text');
      expect((text['target']! as Map)['elementId'], title);
      expect(jsonEncode(text['delta']), contains('Shared idea'));

      await tester.tap(field(OutlineKeys.title(other)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(collab.locks.published?.elementId, isNot(title));

      await tester.pumpWidget(const SizedBox());
      textEditingOf(d.editor).dispose();
      collab.dispose();
      session.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
