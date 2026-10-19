import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/features/canvas/slide_canvas_controller.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides/features/format_painter/format_painter.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';

import '../features/canvas/canvas_rig.dart' show CanvasFixture;
import '../harness/deck_harness.dart';

void main() {
  late CanvasFixture f;
  late DeckHarness d;
  late String text;
  late String plain;

  setUp(() {
    f = CanvasFixture();
    text = f.b.element(
      f.slide,
      ElementKind.shape,
      x: 1300,
      y: 900,
      width: 400,
      height: 120,
      columns: {
        ElementCols.dataJson: jsonEncode({'v': 1, 'geometry': 'rect'}),
        SlidesCols.text: jsonEncode([
          {
            'insert': 'Hi',
            'attributes': {'bold': true},
          },
          {
            'insert': ' there big',
            'attributes': {'color': 'theme:accent2', 'size': 48},
          },
          {
            'insert': '\n',
            'attributes': {'align': 'center'},
          },
        ]),
        ElementCols.textStyleJson: jsonEncode({'v': 1, 'anchor': 'bottom'}),
        ElementCols.effectsJson: jsonEncode({
          'v': 1,
          'shadow': {'color': '#00000040', 'blur': 10, 'dx': 0, 'dy': 4},
        }),
        ElementCols.opacity: 0.5,
      },
    );
    plain = f.b.element(
      f.slide,
      ElementKind.text,
      x: 100,
      y: 950,
      width: 300,
      height: 80,
      columns: {
        SlidesCols.text: jsonEncode([
          {'insert': 'plain\n'},
        ]),
      },
    );
    d = DeckHarness.open(fixture: f.b);
    d.editor.setCurrentSlide(f.slide);
  });
  tearDown(() => d.dispose());

  void select(List<String> ids) => selectionOf(d.editor).select(ids);

  Map<String, Object?>? json(String id, String col) {
    final v = d.model.element(id)!.str(col);
    return v == null ? null : jsonDecode(v) as Map<String, Object?>;
  }

  Future<CommandResult> roundTrip(
    String id, [
    Map<String, Object?> args = const {},
  ]) async {
    final before = d.model.dump();
    final steps = d.undoLabels.length;
    final r = await d.run(id, args);
    expect(r.status, CommandStatus.ok, reason: '$id: ${r.message}');
    final after = d.model.dump();
    expect(after, isNot(equals(before)), reason: '$id changed nothing');
    expect(d.undoLabels.length, steps + 1, reason: '$id: one undo step');
    await d.undo();
    expect(d.model.dump(), before, reason: '$id undo');
    await d.redo();
    expect(d.model.dump(), after, reason: '$id redo');
    return r;
  }

  group('Given fill', () {
    test(
      'when filling a shape and a line then only the shape changes',
      () async {
        select([f.a, f.line]);
        await roundTrip('slides.format.fill', {'color': 'theme:accent3'});
        expect(json(f.a, ElementCols.fillJson), {
          'v': 1,
          'type': 'solid',
          'color': 'theme:accent3',
        });
        expect(d.model.element(f.line)!.str(ElementCols.fillJson), isNull);
      },
    );

    test('when choosing No fill or the theme default then the column is '
        'none or cleared', () async {
      select([f.a]);
      await roundTrip('slides.format.fill', {'none': true});
      expect(json(f.a, ElementCols.fillJson), {'v': 1, 'type': 'none'});
      await roundTrip('slides.format.fill', {'color': null});
      expect(d.model.element(f.a)!.str(ElementCols.fillJson), isNull);
    });

    test('when a gradient is given then it is validated and stored', () async {
      select([f.a]);
      await roundTrip('slides.format.fill', {
        'fill': {
          'type': 'gradient',
          'kind': 'linear',
          'angle': 90,
          'stops': [
            {'at': 0, 'color': '#FF0000'},
            {'at': 1, 'color': 'theme:accent1'},
          ],
        },
      });
      expect(json(f.a, ElementCols.fillJson)!['type'], 'gradient');
      final bad = await d.run('slides.format.fill', {'color': 'reddish'});
      expect(bad.status, CommandStatus.failed);
    });

    test('when only a line is selected then fill is disabled', () {
      select([f.line]);
      final st = d.services.dispatcher.stateOf('slides.format.fill', {
        'none': true,
      });
      expect(st.enabled, isFalse);
      expect(st.disabledReason, 'Select a shape, text box or icon');
    });

    test('when Fill… has no value then the inspector opens on Fill', () async {
      select([f.a]);
      await d.run('slides.format.fill');
      expect(d.editor.inspectorTab, InspectorTab.format);
      expect(d.editor.inspectorSection, 'fill');
      expect(d.undoLabels, isEmpty);
    });
  });

  group('Given borders', () {
    test('when changing a line color then arrows and width are kept', () async {
      select([f.line]);
      await d.run('slides.line.setArrow', {'end': 'end', 'style': 'triangle'});
      await roundTrip('slides.format.stroke', {
        'color': '#FF0000',
        'dash': 'dot',
      });
      expect(json(f.line, ElementCols.strokeJson), {
        'v': 1,
        'color': '#FF0000',
        'width': 6,
        'endArrow': 'triangle',
        'dash': 'dot',
      });
    });

    test(
      'when removing and resetting a border then none / theme default',
      () async {
        select([f.a]);
        await roundTrip('slides.format.stroke', {'width': 4});
        expect(json(f.a, ElementCols.strokeJson), {'v': 1, 'width': 4});
        await roundTrip('slides.format.stroke', {'none': true});
        expect(json(f.a, ElementCols.strokeJson), {'v': 1, 'type': 'none'});
        // A value after none brings the border back.
        await roundTrip('slides.format.stroke', {'color': 'theme:text1'});
        expect(json(f.a, ElementCols.strokeJson), {
          'v': 1,
          'color': 'theme:text1',
        });
        await roundTrip('slides.format.stroke', {'reset': true});
        expect(d.model.element(f.a)!.str(ElementCols.strokeJson), isNull);
      },
    );
  });

  group('Given effects and opacity', () {
    test(
      'when turning shadow and glow on then the effects are merged',
      () async {
        select([f.a]);
        await roundTrip('slides.format.effects', {'shadow': true});
        expect(
          json(f.a, ElementCols.effectsJson)!['shadow'],
          isA<Map<Object?, Object?>>(),
        );
        await roundTrip('slides.format.effects', {'glow': true});
        final fx = json(f.a, ElementCols.effectsJson)!;
        expect(fx.keys, containsAll(['shadow', 'glow']));
        await roundTrip('slides.format.effects', {'shadow': false});
        expect(
          json(f.a, ElementCols.effectsJson)!.containsKey('shadow'),
          isFalse,
        );
        await roundTrip('slides.format.effects', {'reset': true});
        expect(d.model.element(f.a)!.str(ElementCols.effectsJson), isNull);
      },
    );

    test('when setting opacity then 1 clears the column', () async {
      select([f.a, f.g]);
      await roundTrip('slides.format.opacity', {'value': 0.4});
      expect(d.model.element(f.a)!.opacity, 0.4);
      expect(d.model.element(f.g)!.opacity, 0.4);
      await roundTrip('slides.format.opacity', {'value': 1});
      expect(d.model.element(f.a)!.opacity, isNull);
    });
  });

  group('Given the format painter', () {
    test('when painting once then the style is applied in one step and the '
        'brush disarms', () async {
      select([text]);
      final arm = await d.run('slides.format.paintFormat');
      expect(arm.status, CommandStatus.ok);
      expect(FormatPainter.armed(d.editor), isTrue);
      expect(d.undoLabels, isEmpty);

      await roundTrip('slides.format.paintFormat', {
        'targetIds': [f.a],
      });

      expect(
        json(f.a, ElementCols.effectsJson)!['shadow'],
        isA<Map<Object?, Object?>>(),
      );
      expect(d.model.element(f.a)!.opacity, 0.5);
      expect(json(f.a, ElementCols.textStyleJson), {
        'v': 1,
        'anchor': 'bottom',
      });
      // The source's fill (theme default = none set) clears the target's.
      expect(d.model.element(f.a)!.str(ElementCols.fillJson), isNull);
      expect(FormatPainter.armed(d.editor), isFalse);
      expect(d.editor.selectedElementIds, [f.a]);
    });

    test('when painting text then the dominant run and paragraph '
        'attributes apply to the whole body', () async {
      select([text]);
      await d.run('slides.format.paintFormat');
      await d.run('slides.format.paintFormat', {
        'targetIds': [plain],
      });
      final ops =
          jsonDecode(d.model.element(plain)!.str(SlidesCols.text)!) as List;
      expect(ops.first['attributes'], {'color': 'theme:accent2', 'size': 48});
      expect(ops.last['attributes'], {'align': 'center'});
    });

    test('when the brush is clicked twice quickly then it stays armed for '
        'several objects until Esc', () async {
      final t0 = DateTime(2026, 10, 15, 12);
      await withClock(Clock.fixed(t0), () async {
        select([f.a]);
        await d.run('slides.format.paintFormat');
      });
      await withClock(
        Clock.fixed(t0.add(const Duration(milliseconds: 200))),
        () => d.run('slides.format.paintFormat'),
      );
      expect(FormatPainter.of(d.editor).sticky, isTrue);
      for (final id in [f.bShape, f.c]) {
        await d.run('slides.format.paintFormat', {
          'targetIds': [id],
        });
        expect(FormatPainter.armed(d.editor), isTrue);
      }
      expect(d.undoLabels.length, 2);
      await d.run('slides.select.escape');
      expect(FormatPainter.armed(d.editor), isFalse);
    });

    test('when the brush is clicked again later then it disarms', () async {
      final t0 = DateTime(2026, 10, 15, 12);
      await withClock(Clock.fixed(t0), () async {
        select([f.a]);
        await d.run('slides.format.paintFormat');
      });
      await withClock(
        Clock.fixed(t0.add(const Duration(seconds: 2))),
        () => d.run('slides.format.paintFormat'),
      );
      expect(FormatPainter.armed(d.editor), isFalse);
      expect(
        d.services.dispatcher.stateOf('slides.format.paintFormat').checked,
        isFalse,
      );
    });

    test('when a line is painted onto a line then arrowheads come along; '
        'onto a shape they do not', () async {
      final line2 =
          (await d.h.invoke('slides.insert.line', {
                'start': {'x': 0, 'y': 0},
                'end': {'x': 100, 'y': 100},
              }, InvocationSource.mcp)).data!
              as Map;
      select([f.line]);
      await d.run('slides.line.setArrow', {'end': 'end', 'style': 'open'});
      await d.run('slides.format.paintFormat', {'sticky': true});
      await d.run('slides.format.paintFormat', {
        'targetIds': [line2['elementId'], f.a],
      });
      expect(
        json(line2['elementId'] as String, ElementCols.strokeJson)!['endArrow'],
        'open',
      );
      expect(json(f.a, ElementCols.strokeJson), {
        'v': 1,
        'color': '#111111',
        'width': 6,
      });
    });
  });

  group('Given copy and paste style', () {
    test('when pasting without a copied style then it is disabled', () {
      select([f.a]);
      final st = d.services.dispatcher.stateOf('slides.format.pasteStyle');
      expect(st.enabled, isFalse);
      expect(st.disabledReason, 'Copy a style first');
    });

    test('when copying a style and pasting it on two objects then both get '
        'it in one step', () async {
      select([text]);
      final copied = await d.run('slides.format.copyStyle');
      expect((copied.data! as Map)['style'], isA<Map<Object?, Object?>>());
      select([f.a, f.bShape]);
      await roundTrip('slides.format.pasteStyle');
      for (final id in [f.a, f.bShape]) {
        expect(d.model.element(id)!.opacity, 0.5);
      }
    });

    test('when an agent pastes a style payload then it is applied', () async {
      await roundTrip('slides.format.pasteStyle', {
        'ids': [f.a],
        'style': {
          'kind': 'shape',
          'fill': {'type': 'solid', 'color': '#00FF00'},
        },
      });
      expect(json(f.a, ElementCols.fillJson)!['color'], '#00FF00');
    });
  });
}
