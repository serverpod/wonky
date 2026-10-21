import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show MarkdownCodec;

import '../support/editor_harness.dart';

/// Touch (Android) and mouse (desktop, like the web report) interactors.
final _platforms = TargetPlatformVariant({
  TargetPlatform.android,
  TargetPlatform.windows,
});

Delta _doc(List<(String, Map<String, dynamic>?)> lines) {
  final delta = Delta();
  for (final (text, attributes) in lines) {
    delta
      ..insert(text)
      ..insert('\n', attributes);
  }
  return delta;
}

const _quote = {'blockquote': true};

Future<EditorHarness> _pump(
  WidgetTester tester,
  Delta delta, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = EditorHarness(delta);
  addTearDown(h.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: WonkyEditor(controller: h.controller, documentTitle: 'Test doc'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

String _nodeId(EditorHarness h, int index) =>
    h.controller.document.toList()[index].id;

DocumentSelection? _selection(EditorHarness h) => h.editor.composer.selection;

/// Lets the tap recognizer time out so the next tap is not a double tap.
Future<void> _settleTaps(WidgetTester tester) async {
  await tester.pump(kDoubleTapTimeout);
  await tester.pumpAndSettle();
}

/// Redoes [change] like the redo handler: applies it again locally.
void _redo(EditorHarness h, LocalDeltaChange change) => h.controller.applyLocal(
  change.delta,
  label: 'Redo',
  source: LocalChangeSource.undo,
  selectionAfter: change.selectionAfter,
);

Future<void> _pressModB(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

/// The painted areas of the quote lines (their bars), top to bottom.
List<Rect> _quoteBars(WidgetTester tester) =>
    tester
        .widgetList<Semantics>(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'quote',
          ),
        )
        .map(
          (s) => tester.getRect(
            find
                .descendant(
                  of: find.byWidget(s),
                  matching: find.byType(CustomPaint),
                )
                .first,
          ),
        )
        .toList()
      ..sort((a, b) => a.top.compareTo(b.top));

void main() {
  quotedListTests();

  testWidgets('Given a quote of three Markdown paragraphs then their bars '
      'touch: one unbroken bar', (tester) async {
    final delta = const MarkdownCodec()
        .importMarkdown('Intro\n\n> First\n>\n> Second\n>\n> Third\n\nOutro\n')
        .delta;
    expect(
      [for (final op in delta.toList()) op.attributes?['blockquote']],
      [null, true, null, true, null, true, null],
      reason: 'three consecutive quote lines',
    );
    await _pump(tester, delta);

    final bars = _quoteBars(tester);

    expect(bars, hasLength(3));
    for (var i = 1; i < bars.length; i++) {
      expect(bars[i].top, moreOrLessEquals(bars[i - 1].bottom));
    }
  });

  group('Given a single-line quote', () {
    final delta = _doc([('Intro', null), ('Quoted line', _quote)]);

    for (final brightness in Brightness.values) {
      testWidgets(
        'when tapping its text (${brightness.name}) then the caret goes there',
        (tester) async {
          final h = await _pump(tester, delta, brightness: brightness);
          final quoteId = _nodeId(h, 1);

          await tester.placeCaretInParagraph(quoteId, 3);

          expect(_selection(h)?.extent.nodeId, quoteId);
          expect(
            _selection(h)?.extent.nodePosition,
            const TextNodePosition(offset: 3),
          );
        },
        variant: _platforms,
      );
    }

    testWidgets(
      'when typing in it then the text stays in the quote, and undo and redo '
      'work',
      (tester) async {
        final h = await _pump(tester, delta);
        await tester.placeCaretInParagraph(_nodeId(h, 1), 6);

        await tester.typeImeText(' new');
        await tester.pump();

        final typed = _doc([('Intro', null), ('Quoted new line', _quote)]);
        expect(h.delta, typed);
        // One change per keystroke (the undo stack coalesces them).
        final typing = h.changes.toList();
        for (final change in typing.reversed) {
          h.undo(change);
        }
        expect(h.delta, delta);
        for (final change in typing) {
          _redo(h, change);
        }
        expect(h.delta, typed);
      },
      variant: _platforms,
    );

    testWidgets(
      'when double-tapping a word and pressing Mod+B then the word is bold '
      'and undo removes it',
      (tester) async {
        final h = await _pump(tester, delta);
        final quoteId = _nodeId(h, 1);

        await tester.doubleTapInParagraph(quoteId, 8);
        expect(
          _selection(h)?.normalize(h.controller.document),
          DocumentSelection(
            base: DocumentPosition(
              nodeId: quoteId,
              nodePosition: const TextNodePosition(offset: 7),
            ),
            extent: DocumentPosition(
              nodeId: quoteId,
              nodePosition: const TextNodePosition(offset: 11),
            ),
          ),
        );
        await _pressModB(tester);

        expect(
          h.delta,
          Delta()
            ..insert('Intro\n')
            ..insert('Quoted ')
            ..insert('line', {'bold': true})
            ..insert('\n', _quote),
        );
        h.undo(h.changes.last);
        expect(h.delta, delta);
      },
      variant: _platforms,
    );
  });

  group('Given a three-line quote', () {
    final delta = _doc([
      ('Intro', null),
      ('First line', _quote),
      ('Second line', _quote),
      ('Third line', _quote),
      ('Outro', null),
    ]);

    testWidgets('when tapping each line then the caret goes into that line', (
      tester,
    ) async {
      final h = await _pump(tester, delta);

      for (final index in [3, 1, 2]) {
        await tester.placeCaretInParagraph(_nodeId(h, index), 2);
        await _settleTaps(tester);

        expect(_selection(h)?.extent.nodeId, _nodeId(h, index));
      }
    }, variant: _platforms);

    testWidgets(
      'when typing in the middle line and pressing Enter then a new quote line '
      'is added, and undo restores the quote',
      (tester) async {
        final h = await _pump(tester, delta);
        await tester.placeCaretInParagraph(_nodeId(h, 2), 11);

        await tester.typeImeText('!');
        await tester.pressEnter();
        await tester.typeImeText('More');
        await tester.pump();

        expect(
          h.delta,
          _doc([
            ('Intro', null),
            ('First line', _quote),
            ('Second line!', _quote),
            ('More', _quote),
            ('Third line', _quote),
            ('Outro', null),
          ]),
        );
        for (final change in h.changes.reversed.toList()) {
          h.undo(change);
        }
        expect(h.delta, delta);
      },
      variant: _platforms,
    );

    testWidgets(
      'when selecting across the lines and pressing Mod+B then all of them '
      'are bold',
      (tester) async {
        final h = await _pump(tester, delta);
        await tester.placeCaretInParagraph(_nodeId(h, 1), 0);
        // "Intro\n" is 6 characters; select from "First" to the end of
        // "Third line".
        h.select(6, 6 + 'First line\nSecond line\nThird line'.length);
        await tester.pump();

        await _pressModB(tester);

        expect(
          h.delta,
          Delta()
            ..insert('Intro\n')
            ..insert('First line', {'bold': true})
            ..insert('\n', _quote)
            ..insert('Second line', {'bold': true})
            ..insert('\n', _quote)
            ..insert('Third line', {'bold': true})
            ..insert('\n', _quote)
            ..insert('Outro\n'),
        );
      },
      variant: _platforms,
    );
  });

  // An unquoted list item between two quotes (two quotes, Write 04 §14).
  group('Given a list between quote lines', () {
    final delta = _doc([
      ('Quote one', _quote),
      ('Item', {'list': 'bullet'}),
      ('Quote two', _quote),
    ]);

    testWidgets(
      'when tapping and typing in the item and the quote after it then both '
      'are edited, and undo restores them',
      (tester) async {
        final h = await _pump(tester, delta);

        await tester.placeCaretInParagraph(_nodeId(h, 1), 4);
        expect(_selection(h)?.extent.nodeId, _nodeId(h, 1));
        await tester.typeImeText('s');
        await _settleTaps(tester);
        await tester.placeCaretInParagraph(_nodeId(h, 2), 9);
        expect(_selection(h)?.extent.nodeId, _nodeId(h, 2));
        await tester.typeImeText('!');
        await tester.pump();

        expect(
          h.delta,
          _doc([
            ('Quote one', _quote),
            ('Items', {'list': 'bullet'}),
            ('Quote two!', _quote),
          ]),
        );
        for (final change in h.changes.reversed.toList()) {
          h.undo(change);
        }
        expect(h.delta, delta);
      },
      variant: _platforms,
    );
  });
}

/// Lists inside quotes (Write 04 §14): list lines with `blockquote: true`.
void quotedListTests() {
  const bullet = {'list': 'bullet', 'blockquote': true};

  group('Given a quote with a list inside', () {
    final delta = _doc([
      ('Intro', null),
      ('Said:', _quote),
      ('One', bullet),
      ('Two', bullet),
      ('Done', {'list': 'checked', 'blockquote': true}),
      ('Outro', null),
    ]);

    testWidgets('then the items are quoted list nodes under one unbroken '
        'bar', (tester) async {
      final h = await _pump(tester, delta);
      final nodes = h.controller.document.toList();

      expect(nodes[2], isA<ListItemNode>());
      expect(nodes[4], isA<TaskNode>());
      expect(
        [for (final n in nodes) n.getMetadataValue('wonkyQuoted') == true],
        [false, false, true, true, true, false],
      );
      final bars = _quoteBars(tester);
      expect(bars, hasLength(4));
      for (var i = 1; i < bars.length; i++) {
        expect(bars[i].top, moreOrLessEquals(bars[i - 1].bottom));
      }
      expect(h.delta, delta, reason: 'the mapping round-trips');
    });

    testWidgets('when tapping and typing in an item then it stays in the '
        'quote, and undo restores it', (tester) async {
      final h = await _pump(tester, delta);

      await tester.placeCaretInParagraph(_nodeId(h, 3), 3);
      expect(_selection(h)?.extent.nodeId, _nodeId(h, 3));
      await tester.typeImeText('!');
      await tester.pump();

      expect(
        h.delta,
        _doc([
          ('Intro', null),
          ('Said:', _quote),
          ('One', bullet),
          ('Two!', bullet),
          ('Done', {'list': 'checked', 'blockquote': true}),
          ('Outro', null),
        ]),
      );
      for (final change in h.changes.reversed.toList()) {
        h.undo(change);
      }
      expect(h.delta, delta);
    }, variant: _platforms);

    testWidgets('when pressing Enter in an item then the new item is in the '
        'quote; Enter on it again leaves the list but not the quote', (
      tester,
    ) async {
      final h = await _pump(tester, delta);
      await tester.placeCaretInParagraph(_nodeId(h, 3), 3);

      await tester.pressEnter();
      await tester.typeImeText('Three');
      await tester.pressEnter();
      await tester.pressEnter();
      await tester.typeImeText('Back in the quote');
      await tester.pump();

      expect(
        h.delta,
        _doc([
          ('Intro', null),
          ('Said:', _quote),
          ('One', bullet),
          ('Two', bullet),
          ('Three', bullet),
          ('Back in the quote', _quote),
          ('Done', {'list': 'checked', 'blockquote': true}),
          ('Outro', null),
        ]),
      );
      for (final change in h.changes.reversed.toList()) {
        h.undo(change);
      }
      expect(h.delta, delta);
    }, variant: _platforms);

    testWidgets('when pressing Backspace at the start of an item then it '
        'becomes a quote line', (tester) async {
      final h = await _pump(tester, delta);
      await tester.placeCaretInParagraph(_nodeId(h, 2), 0);

      await tester.pressBackspace();
      await tester.pump();

      expect(
        h.delta,
        _doc([
          ('Intro', null),
          ('Said:', _quote),
          ('One', _quote),
          ('Two', bullet),
          ('Done', {'list': 'checked', 'blockquote': true}),
          ('Outro', null),
        ]),
      );
    }, variant: _platforms);

    testWidgets('when pressing Tab in an item then it is indented and stays '
        'in the quote', (tester) async {
      final h = await _pump(tester, delta);
      await tester.placeCaretInParagraph(_nodeId(h, 3), 0);

      await tester.pressTab();
      await tester.pump();

      expect(
        h.delta,
        _doc([
          ('Intro', null),
          ('Said:', _quote),
          ('One', bullet),
          ('Two', {...bullet, 'indent': 1}),
          ('Done', {'list': 'checked', 'blockquote': true}),
          ('Outro', null),
        ]),
      );
    }, variant: _platforms);
  });

  group('Given a quote line', () {
    final delta = _doc([('Said:', _quote), ('', _quote)]);

    for (final (prefix, attributes) in [
      ('- ', bullet),
      ('1. ', {'list': 'ordered', 'blockquote': true}),
      ('[ ] ', {'list': 'unchecked', 'blockquote': true}),
    ]) {
      testWidgets('when typing "$prefix" at its start then it becomes a list '
          'item inside the quote', (tester) async {
        final h = await _pump(tester, delta);
        await tester.placeCaretInParagraph(_nodeId(h, 1), 0);

        await tester.typeImeText('${prefix}item');
        await tester.pump();

        expect(h.delta, _doc([('Said:', _quote), ('item', attributes)]));
      });
    }
  });

  group('Given the block type commands', () {
    late EditorHarness h;
    late WriteEditorCommands commands;
    setUp(() {
      h = EditorHarness(
        _doc([
          ('a', _quote),
          ('b', {'list': 'bullet'}),
        ]),
      );
      commands = WriteEditorCommands(h.controller);
    });
    tearDown(() => h.dispose());

    test('when making a quote line a bulleted list then it is a list inside '
        'the quote, and toggling the list off gives the quote line back', () {
      h.select(0);

      commands.setBlockType(BlockKind.bulleted);
      expect(
        h.delta,
        _doc([
          ('a', bullet),
          ('b', {'list': 'bullet'}),
        ]),
      );
      expect(commands.selectionInQuote, isTrue);
      commands.setBlockType(BlockKind.bulleted);

      expect(
        h.delta,
        _doc([
          ('a', _quote),
          ('b', {'list': 'bullet'}),
        ]),
      );
    });

    test('when toggling Quote on a list item then it moves into a quote, and '
        'toggling it again takes it out (still a list item)', () {
      h.select(2);

      commands.setBlockType(BlockKind.quote);
      expect(h.delta, _doc([('a', _quote), ('b', bullet)]));
      commands.setBlockType(BlockKind.quote);

      expect(
        h.delta,
        _doc([
          ('a', _quote),
          ('b', {'list': 'bullet'}),
        ]),
      );
    });

    test('when turning a quoted item into a heading then it leaves the '
        'quote', () {
      h.select(0);
      commands.setBlockType(BlockKind.bulleted);

      commands.setBlockType(BlockKind.heading2, toggle: false);

      expect(
        h.delta,
        _doc([
          ('a', {'header': 2}),
          ('b', {'list': 'bullet'}),
        ]),
      );
    });
  });
}
