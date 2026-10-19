import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show CommandState;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides/features/masters/masters_targets.dart';
import 'package:wonky_slides/features/selection/selection_controller.dart';
import 'package:wonky_slides/features/canvas/slide_canvas_controller.dart'
    show selectionOf;
import 'package:wonky_slides_core/clipboard.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart';

import '../harness/deck_harness.dart';

/// Masters mode, layout/master commands and the theme editor commands
/// (Slides 05 §8; SL-28) run headless through the real dispatcher and undo
/// stack: every edit is one undo step, undo and redo restore every row.
void main() {
  late DeckHarness d;
  late DeckBuilder b;
  late String s1, s2, s3, s4;

  setUp(() {
    b = DeckBuilder();
    s1 = b.slide(layoutKey: 'title', title: 'Q3 review');
    s2 = b.slide(title: 'Mission', body: 'Make it effortless');
    s3 = b.slide(title: 'Plan', body: 'Ship it');
    s4 = b.slide(title: 'Later');
    d = DeckHarness.open(fixture: b);
  });
  tearDown(() => d.dispose());

  DeckModel m() => d.model;
  DeckEditorController ed() => d.editor;
  SelectionController sel() => selectionOf(ed());
  CommandState state(String id, [Map<String, Object?> args = const {}]) =>
      d.services.dispatcher.stateOf(id, args);
  String layout(String key) => b.layoutId(key);
  String master() => b.themeIds.masterId;
  String theme() => b.themeIds.themeId;

  Map<String, Object?> dump() =>
      jsonDecode(jsonEncode(m().dump(), toEncodable: (v) => '$v'))
          as Map<String, Object?>;

  Future<void> undoRedo(Map<String, Object?> before) async {
    final after = dump();
    await d.undo();
    expect(dump(), before, reason: 'undo restores every row');
    await d.redo();
    expect(dump(), after, reason: 'redo re-applies every row');
  }

  Future<CommandResult> run(String id, [Map<String, Object?> a = const {}]) =>
      d.run(id, a);

  SlideElementRec placeholderOf(String owner, SlidePlaceholderType t) =>
      m().elementsOf(owner).firstWhere((e) => e.placeholderType == t);

  group('Given a deck in the Wonky theme', () {
    test('when masters mode is entered then it edits the current slide\'s '
        'layout and the canvas surface is that layout', () async {
      ed().setCurrentSlide(s2);

      await run('slides.view.setMode', {'mode': 'masters'});

      expect(ed().mode, DeckViewMode.masters);
      expect(ed().surfaceId, layout('titleBody'));
      expect(ed().surfaceKind, ElementOwnerKind.layout);
      expect(sel().slide!.isSurface, isTrue);
      expect(ed().describeState()['masterTargetId'], layout('titleBody'));
    });

    test('when a master is chosen with masterId then the master is edited, '
        'and Escape with nothing selected returns to Normal view', () async {
      await run('slides.view.setMode', {
        'mode': 'masters',
        'masterId': master(),
      });
      expect(ed().surfaceId, master());
      expect(ed().surfaceKind, ElementOwnerKind.master);

      expect(state('slides.masters.exit').enabled, isTrue);
      await run('slides.masters.exit');
      expect(ed().mode, DeckViewMode.normal);
      expect(ed().surfaceId, s1);
    });

    test('when a layout placeholder is moved in masters mode then slides '
        'with an inherited title follow and materialized ones stay (05 AC '
        '4) — one undo step', () async {
      // s3's title frame is materialized by a move on the slide; s2's
      // title inherits.
      final s3Title = placeholderOf(s3, SlidePlaceholderType.title);
      ed().setCurrentSlide(s3);
      await run('slides.element.move', {
        'ids': [s3Title.id],
        'dx': 0,
        'dy': 8,
      });
      final s3Y = m().element(s3Title.id)!.y!;
      await run('slides.view.setMode', {
        'mode': 'masters',
        'layoutId': layout('titleBody'),
      });
      final layoutTitle = placeholderOf(
        layout('titleBody'),
        SlidePlaceholderType.title,
      );
      final y0 = layoutTitle.y!;
      final before = dump();
      final steps = d.undoLabels.length;

      await run('slides.element.move', {
        'ids': [layoutTitle.id],
        'dx': 0,
        'dy': 40,
      });

      expect(m().element(layoutTitle.id)!.y, y0 + 40);
      ResolvedElement titleOn(String slide) => ed().resolver
          .resolve(slide)!
          .elements
          .firstWhere((e) => e.placeholderType == SlidePlaceholderType.title);
      expect(titleOn(s2).frame.y, y0 + 40);
      expect(titleOn(s3).frame.y, s3Y);
      expect(d.undoLabels, hasLength(steps + 1));
      await undoRedo(before);
    });

    test('when the text of a layout placeholder changes then it is the '
        'prompt of every empty instance', () async {
      final body = placeholderOf(
        layout('titleBody'),
        SlidePlaceholderType.body,
      );
      d.registerOp(
        'test.setText',
        (a) => SetText(ElementText(body.id), plainDelta('Your agenda here')),
      );

      await run('test.setText');

      ResolvedElement bodyOn(String slide) => ed().resolver
          .resolve(slide)!
          .elements
          .firstWhere((e) => e.placeholderType == SlidePlaceholderType.body);
      expect(bodyOn(s4).prompt, 'Your agenda here');
      expect(bodyOn(s2).prompt, isNull, reason: 's2 has text');
    });

    test('when a text box is inserted in masters mode then the layout owns '
        'it (a decoration on every slide using the layout)', () async {
      await run('slides.view.setMode', {
        'mode': 'masters',
        'layoutId': layout('titleBody'),
      });
      final before = dump();

      final r = await d.h.invoke('slides.insert.textBox', {
        'x': 100,
        'y': 900,
        'text': 'Confidential',
      }, InvocationSource.mcp);

      final id = (r.data! as Map)['elementId'] as String;
      final e = m().element(id)!;
      expect(e.layoutId, layout('titleBody'));
      expect(e.slideId, isNull);
      expect(
        ed().resolver.resolve(s2)!.layoutElements.map((x) => x.id),
        contains(id),
      );
      await undoRedo(before);
    });

    test(
      'when a placeholder is inserted on a layout then it refines the '
      'master placeholder of its type, is selected, and is one undo step',
      () async {
        await run('slides.view.setMode', {
          'mode': 'masters',
          'layoutId': layout('blank'),
        });
        final before = dump();

        final r = await run('slides.layout.insertPlaceholder', {
          'type': 'title',
        });

        final id = (r.data! as Map)['elementId'] as String;
        final e = m().element(id)!;
        expect(e.layoutId, layout('blank'));
        expect(e.placeholderType, SlidePlaceholderType.title);
        expect(
          e.placeholderOf,
          placeholderOf(master(), SlidePlaceholderType.title).id,
        );
        expect(SlidesText.plainText(e.text).trim(), 'Click to add title');
        expect(ed().selectedElementIds, [id]);
        expect(d.undoLabels, hasLength(1));
        await undoRedo(before);
      },
    );

    test('when a picture placeholder is inserted on a master then it gets '
        'the 05 §4 geometry and an image kind', () async {
      final r = await run('slides.layout.insertPlaceholder', {
        'type': 'picture',
        'masterId': master(),
      });

      final e = m().element((r.data! as Map)['elementId'] as String)!;
      expect(e.masterId, master());
      expect(e.kind, ElementKind.image);
      expect(e.frame, const SuRect(480, 270, 960, 540));
    });

    test('when Insert placeholder is asked for outside masters mode then it '
        'is disabled with the reason', () {
      final st = state('slides.layout.insertPlaceholder', {'type': 'body'});
      expect(st.enabled, isFalse);
      expect(st.disabledReason, isNotNull);
    });

    test('when a layout is added, duplicated, renamed, moved and hidden then '
        'each is one undo step that undo and redo restore', () async {
      await run('slides.view.setMode', {
        'mode': 'masters',
        'layoutId': layout('quote'),
      });
      for (final (id, args) in <(String, Map<String, Object?>)>[
        ('slides.layout.add', {}),
        ('slides.layout.duplicate', {'layoutId': layout('quote')}),
        ('slides.layout.rename', {'layoutId': layout('quote'), 'name': 'Cite'}),
        ('slides.layout.move', {'layoutId': layout('quote'), 'to': 0}),
        ('slides.layout.toggleHidden', {'layoutId': layout('quote')}),
        (
          'slides.layout.setHideMasterElements',
          {'layoutId': layout('quote'), 'value': true},
        ),
        (
          'slides.layout.setBackground',
          {'layoutId': layout('quote'), 'color': 'theme:bg2'},
        ),
      ]) {
        final before = dump();
        final n = d.undoLabels.length;
        final r = await run(id, args);
        expect(r.isOk, isTrue, reason: '$id: ${r.message}');
        expect(d.undoLabels, hasLength(n + 1), reason: id);
        await undoRedo(before);
      }
      final q = m().layout(layout('quote'))!;
      expect(q.name, 'Cite');
      expect(q.hidden, isTrue);
      expect(q.hideMasterElements, isTrue);
      final ordered = [...m().layoutsOf(master())]
        ..sort((a, c) => a.sortKey.compareTo(c.sortKey));
      expect(ordered.first.id, q.id);
    });

    test('when a new layout is added in masters mode then it is shown and '
        'holds a title placeholder', () async {
      await run('slides.view.setMode', {'mode': 'masters'});

      final r = await run('slides.layout.add');

      final id = (r.data! as Map)['layoutId'] as String;
      expect(ed().surfaceId, id);
      expect(m().layout(id)!.name, startsWith('Layout '));
      expect(
        m().elementsOf(id).single.placeholderType,
        SlidePlaceholderType.title,
      );
    });

    test(
      'when a layout used by slides is deleted with replaceWith then '
      'those slides move to it and the layout goes — one undo step',
      () async {
        await run('slides.view.setMode', {
          'mode': 'masters',
          'layoutId': layout('titleBody'),
        });
        final before = dump();

        final r = await run('slides.layout.delete', {
          'layoutId': layout('titleBody'),
          'replaceWith': layout('titleOnly'),
        });

        expect(r.isOk, isTrue, reason: r.message);
        expect(m().layout(layout('titleBody')), isNull);
        expect(m().slide(s2)!.layoutId, layout('titleOnly'));
        expect(m().slide(s3)!.layoutId, layout('titleOnly'));
        expect(
          SlidesText.plainText(
            placeholderOf(s2, SlidePlaceholderType.title).text,
          ).trim(),
          'Mission',
        );
        expect(ed().surfaceId, isNot(layout('titleBody')));
        expect(d.undoLabels, hasLength(1));
        await undoRedo(before);
      },
    );

    test('when an agent deletes a used layout without replaceWith then it '
        'fails with the usage, and an unused one is deleted', () async {
      final r = await d.h.invoke('slides.layout.delete', {
        'layoutId': layout('titleBody'),
      }, InvocationSource.mcp);
      expect(r.status, CommandStatus.failed);
      expect(r.message, contains('3 slides'));

      final ok = await run('slides.layout.delete', {
        'layoutId': layout('quote'),
      });
      expect(ok.isOk, isTrue);
      expect(m().layout(layout('quote')), isNull);
    });

    test('when the replacement of a deleted layout is proposed then it is '
        'Title and content of the same master', () {
      final l = m().layout(layout('twoColumns'))!;
      expect(MastersTargets.replacementFor(ed(), l)!.id, layout('titleBody'));
    });

    test('when masters are added, duplicated, renamed and deleted then each '
        'is one step; the last or a used master can\'t be deleted', () async {
      expect(
        state('slides.master.delete', {'masterId': master()}).enabled,
        isFalse,
      );
      final before = dump();
      final r = await run('slides.master.duplicate', {'masterId': master()});
      final copy = (r.data! as Map)['masterId'] as String;
      expect(m().layoutsOf(copy), hasLength(m().layoutsOf(master()).length));
      await undoRedo(before);

      await run('slides.master.rename', {'masterId': copy, 'name': 'Dark'});
      expect(m().master(copy)!.name, 'Dark');
      await run('slides.master.setBackground', {
        'masterId': copy,
        'color': '#112233',
      });
      expect(m().master(copy)!.backgroundJson, contains('#112233'));
      expect(state('slides.master.delete', {'masterId': copy}).enabled, isTrue);
      await run('slides.master.delete', {'masterId': copy});
      expect(m().master(copy), isNull);
      final add = await run('slides.master.add', {'themeId': theme()});
      expect(m().master((add.data! as Map)['masterId'] as String), isNotNull);
    });

    test('when Edit theme is invoked then masters mode opens on the theme '
        'with the Theme tab', () async {
      await run('slides.theme.edit');

      expect(ed().mode, DeckViewMode.masters);
      expect(ed().surfaceId, master());
      expect(ed().inspectorTab, InspectorTab.theme);
      // The Theme tab reads as the Slide tab outside masters mode.
      ed().setMode(DeckViewMode.normal);
      expect(ed().inspectorTab, InspectorTab.slide);
    });

    test('when a theme column is updated then only that column changes and '
        'it is one undo step; invalid JSON is refused', () async {
      final before = dump();
      final colors = SlideResolver.themeDataOf(
        m().theme(theme()),
      ).colors.toJson();
      (colors['light']! as Map)['accent1'] = '#FF0000';

      final r = await run('slides.theme.update', {
        'themeId': theme(),
        'columns': {'colorsJson': colors},
      });

      expect(r.isOk, isTrue, reason: r.message);
      final data = SlideResolver.themeDataOf(m().theme(theme()));
      expect(data.colors.light.accent(1), 0xffff0000);
      expect(d.undoLabels, hasLength(1));
      await undoRedo(before);

      final bad = await run('slides.theme.update', {
        'themeId': theme(),
        'columns': {
          'colorsJson': {'v': 1, 'light': <String, Object?>{}},
        },
      });
      expect(bad.status, CommandStatus.failed);
    });

    test('when dark colors are derived then the dark scheme passes the '
        'contrast checks and undo restores the hand-tuned one', () async {
      final before = dump();
      final r = await run('slides.theme.deriveDarkColors', {
        'themeId': theme(),
      });

      expect(r.isOk, isTrue);
      final colors = SlideResolver.themeDataOf(m().theme(theme())).colors;
      expect(
        ThemeContrast.check(
          colors,
          SlideAppearance.dark,
        ).every((x) => x.passes),
        isTrue,
      );
      await undoRedo(before);
    });

    test('when an edited built-in theme is reset then its JSON columns are '
        'the built-in\'s again', () async {
      await run('slides.theme.update', {
        'themeId': theme(),
        'name': 'Mine',
        'columns': {
          'fontsJson': {
            'v': 1,
            'heading': {'family': 'Lato', 'weight': 700},
            'body': {'family': 'Lato', 'weight': 400},
            'mono': {'family': 'JetBrains Mono', 'weight': 400},
          },
        },
      });
      expect(m().theme(theme())!.name, 'Mine');

      await run('slides.theme.resetToBuiltIn', {'themeId': theme()});

      final data = SlideResolver.themeDataOf(m().theme(theme()));
      expect(data.fonts, BuiltInThemes.package('wonky')!.theme.fonts);
      expect(m().theme(theme())!.name, 'Mine', reason: 'the name is kept');
    });

    test('when elements are copied on a layout and pasted then the copies '
        'stay on the layout', () async {
      await run('slides.view.setMode', {
        'mode': 'masters',
        'layoutId': layout('titleBody'),
      });
      await d.h.invoke('slides.insert.textBox', {
        'x': 100,
        'y': 900,
        'text': 'Logo',
      }, InvocationSource.mcp);
      final id = ed().selectedElementIds.single;
      final payload = SlidesClipboardCodec.copyElements(m(), [id]);
      expect(payload['sourceSlideId'], layout('titleBody'));

      await run('slides.edit.duplicate');

      final copies = [
        for (final e in m().elementsOf(layout('titleBody')))
          if (e.placeholderType == null) e.id,
      ];
      expect(copies, hasLength(2));
    });

    test('when an undo of a layout edit runs in Normal view then no layout '
        'element is selected on the slide', () async {
      await run('slides.view.setMode', {
        'mode': 'masters',
        'layoutId': layout('titleBody'),
      });
      final title = placeholderOf(
        layout('titleBody'),
        SlidePlaceholderType.title,
      );
      sel().select([title.id]);
      await run('slides.element.move', {
        'ids': [title.id],
        'dx': 10,
        'dy': 0,
      });
      await run('slides.view.setMode', {'mode': 'normal'});

      await d.undo();

      expect(ed().selectedElementIds, isEmpty);
    });

    test('when the editor switches to Viewing mode then masters mode is '
        'left', () async {
      await run('slides.view.setMode', {'mode': 'masters'});
      ed().setViewMode(true);
      expect(ed().mode, DeckViewMode.normal);
    });
  });
}
