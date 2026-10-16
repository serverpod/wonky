import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:shad/shad.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_rich_editor/testing.dart';
import 'package:wonky_rich_editor/wonky_rich_editor.dart';
import 'package:wonky_ui/testing.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

class _Rig {
  _Rig(this.controller);

  final MarkdownEditingController controller;
  var submitted = 0;
  final focus = FocusNode();

  String get md => controller.markdown;
}

Future<_Rig> _pump(
  WidgetTester tester, {
  String markdown = '',
  Brightness brightness = Brightness.light,
  int? maxLength,
  bool enabled = true,
  bool readOnly = false,
  RichLinkRequest? requestLink,
  MarkdownBlockFeatures features = MarkdownBlockFeatures.all,
  double width = 500,
  RichEditorSpellChecker? spellChecker,
}) async {
  final rig = _Rig(
    MarkdownEditingController(markdown: markdown, features: features),
  );
  addTearDown(rig.controller.dispose);
  addTearDown(rig.focus.dispose);
  await pumpWonky(
    tester,
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WonkyRichEditor(
              controller: rig.controller,
              hint: 'Say something',
              maxLength: maxLength,
              enabled: enabled,
              readOnly: readOnly,
              requestLink: requestLink,
              onSubmit: () => rig.submitted++,
              spellChecker: spellChecker,
            ),
            ShadButton(focusNode: rig.focus, child: const Text('Next')),
          ],
        ),
      ),
    ),
    brightness: brightness,
  );
  return rig;
}

Future<void> _focus(WidgetTester tester) async {
  richEditorStateOf(tester, _key('markdown.composer')).focus();
  await tester.pump();
}

Future<void> _chord(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pump();
}

void _select(MarkdownEditingController c, int block, int start, int end) {
  final id = c.document.getNodeAt(block)!.id;
  c.editor.execute([
    ChangeSelectionRequest(
      DocumentSelection(
        base: DocumentPosition(
          nodeId: id,
          nodePosition: TextNodePosition(offset: start),
        ),
        extent: DocumentPosition(
          nodeId: id,
          nodePosition: TextNodePosition(offset: end),
        ),
      ),
      SelectionChangeType.expandSelection,
      SelectionReason.userInteraction,
    ),
  ]);
}

/// A clipboard on the platform channel.
String? _mockClipboard(WidgetTester tester, [String? initial]) {
  String? text = initial;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        text = (call.arguments as Map)['text'] as String?;
      }
      if (call.method == 'Clipboard.getData') return {'text': text};
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  _clipboard = () => text;
  return text;
}

String? Function() _clipboard = () => null;

/// Knows a few words; suggests from a table.
class _Checker extends ChangeNotifier implements RichEditorSpellChecker {
  final known = {'hello', 'world', 'the', 'plan', 'code', 'say'};
  final ignored = <String>{};
  final added = <String>[];
  @override
  bool underline = true;

  @override
  List<SpellRange> check(String text, {List<(int, int)> skip = const []}) => [
    for (final m in RegExp('[a-zA-Z]+').allMatches(text))
      if (m.end - m.start > 1 &&
          !skip.any((r) => m.start < r.$2 && m.end > r.$1) &&
          !known.contains(m[0]!.toLowerCase()) &&
          !ignored.contains(m[0]) &&
          !added.contains(m[0]))
        SpellRange(m.start, m.end, m[0]!),
  ];

  @override
  List<String> suggestionsFor(String word, {int max = 5}) =>
      const {
        'helo': ['hello', 'help'],
        'wrold': ['world'],
      }[word] ??
      const [];

  @override
  void ignore(String word) {
    ignored.add(word);
    notifyListeners();
  }

  @override
  Future<bool> addToDictionary(String word) async {
    added.add(word);
    notifyListeners();
    return true;
  }
}

bool _toggled(WidgetTester tester, String id) =>
    tester.widget<ShadToggle>(_key('markdown.composer.$id')).value;

void main() {
  for (final b in Brightness.values) {
    testWidgets('Given the editor in ${b.name} when typing Markdown then it '
        'is formatted as typed and the field reads as Markdown', (
      tester,
    ) async {
      final r = await _pump(tester, brightness: b);
      expect(find.text('Say something', findRichText: true), findsOneWidget);
      await _focus(tester);
      await tester.typeImeText('# Plan');
      await tester.pressEnter();
      await tester.typeImeText('- [] check **this**');
      await tester.pump();
      expect(r.md, '# Plan\n\n- [ ] check **this**');
      expect(_toggled(tester, 'tasks'), isTrue);
      await settleTooltips(tester);
    });
  }

  testWidgets('Given a selection when the toolbar is used then styles and '
      'blocks change and the buttons show the state', (tester) async {
    final r = await _pump(tester, markdown: 'hello world');
    await _focus(tester);
    _select(r.controller, 0, 6, 11);
    await tester.pump();
    expect(_toggled(tester, 'bold'), isFalse);
    await tester.tap(_key('markdown.composer.bold'));
    await tester.pump();
    expect(r.md, 'hello **world**');
    expect(_toggled(tester, 'bold'), isTrue);
    await tester.tap(_key('markdown.composer.strike'));
    await tester.pump();
    expect(r.md, 'hello **~~world~~**');
    await tester.tap(_key('markdown.composer.numbers'));
    await tester.pump();
    expect(r.md, '1. hello **~~world~~**');
    expect(_toggled(tester, 'numbers'), isTrue);
    await tester.tap(_key('markdown.composer.quote'));
    await tester.pump();
    expect(r.md, '> hello **~~world~~**');
    // No code blocks (specs/16 §7.3).
    expect(_key('markdown.composer.codeBlock'), findsNothing);
    await settleTooltips(tester);
  });

  testWidgets('Given the keyboard when the shortcuts are pressed then they '
      'format, undo and redo locally and submit', (tester) async {
    final r = await _pump(tester, markdown: 'a b');
    await _focus(tester);
    _select(r.controller, 0, 0, 1);
    await _chord(tester, LogicalKeyboardKey.keyB);
    expect(r.md, '**a** b');
    await _chord(tester, LogicalKeyboardKey.keyI);
    expect(r.md, '***a*** b');
    await _chord(tester, LogicalKeyboardKey.keyE);
    expect(r.md, '`a` b');
    await _chord(tester, LogicalKeyboardKey.keyX, shift: true);
    expect(r.md, '`a` b', reason: 'no strikethrough on code');
    await _chord(tester, LogicalKeyboardKey.digit8, shift: true);
    expect(r.md, '- `a` b');
    await _chord(tester, LogicalKeyboardKey.keyZ);
    expect(r.md, '`a` b');
    await _chord(tester, LogicalKeyboardKey.keyZ);
    expect(r.md, '***a*** b');
    await _chord(tester, LogicalKeyboardKey.keyZ, shift: true);
    expect(r.md, '`a` b');
    await _chord(tester, LogicalKeyboardKey.enter);
    expect(r.submitted, 1);
  });

  testWidgets('Given Mod+K when a URL is entered then the selection links '
      'to it, and on a link the dialog edits or removes it', (tester) async {
    String? asked;
    RichLinkResult? answer = const RichLinkResult('wonky.work');
    final r = await _pump(
      tester,
      markdown: 'see docs',
      requestLink: (context, current) async {
        asked = current;
        return answer;
      },
    );
    await _focus(tester);
    _select(r.controller, 0, 4, 8);
    await _chord(tester, LogicalKeyboardKey.keyK);
    await tester.pump();
    expect(asked, isNull);
    expect(r.md, 'see [docs](https://wonky.work)');
    expect(_toggled(tester, 'link'), isTrue);
    answer = const RichLinkResult(null);
    await tester.tap(_key('markdown.composer.link'));
    await tester.pump();
    expect(asked, 'https://wonky.work');
    expect(r.md, 'see docs');
    await settleTooltips(tester);
  });

  testWidgets('Given the built-in link dialog when javascript: is entered '
      'then it is refused', (tester) async {
    final r = await _pump(tester, markdown: 'x');
    await _focus(tester);
    _select(r.controller, 0, 0, 1);
    await _chord(tester, LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();
    expect(_key('dialog.markdown.link'), findsOneWidget);
    await tester.enterText(_key('dialog.markdown.link.url'), 'javascript:1');
    await tester.tap(_key('dialog.markdown.link.ok'));
    await tester.pumpAndSettle();
    expect(_key('dialog.markdown.link'), findsOneWidget);
    await tester.enterText(_key('dialog.markdown.link.url'), 'a.b');
    await tester.tap(_key('dialog.markdown.link.ok'));
    await tester.pumpAndSettle();
    expect(r.md, '[x](https://a.b)');
  });

  testWidgets('Given Markdown on the clipboard when pasted then it is '
      'converted, and Mod+Shift+V pastes it as text', (tester) async {
    final r = await _pump(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': '**hi** there\n\n- one'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _focus(tester);
    await _chord(tester, LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(r.md, '**hi** there\n\n- one');
    r.controller.markdown = '';
    await tester.pump();
    await _chord(tester, LogicalKeyboardKey.keyV, shift: true);
    await tester.pump();
    expect(r.controller.document.first, isA<ParagraphNode>());
    expect(
      (r.controller.document.first as ParagraphNode).text.toPlainText(),
      '**hi** there',
    );
  });

  testWidgets('Given a list when Tab is pressed then the item indents; '
      'outside lists Tab moves the focus on', (tester) async {
    final r = await _pump(tester, markdown: '- a\n- b');
    await _focus(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(r.md, '- a\n  - b');
    r.controller.markdown = 'plain';
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(r.focus.hasFocus, isTrue);
    expect(r.md, 'plain');
  });

  testWidgets('Given a max length when the text nears it then a counter '
      'shows and typing stops at the limit', (tester) async {
    final r = await _pump(tester, markdown: '1234567', maxLength: 10);
    expect(_key('markdown.composer.count'), findsNothing);
    await _focus(tester);
    await tester.typeImeText('89');
    await tester.pump();
    expect(find.text('9 / 10'), findsOneWidget);
    await tester.typeImeText('abc');
    await tester.pump();
    expect(r.md, '123456789a');
  });

  testWidgets('Given a disabled or read-only editor then nothing changes '
      'and the toolbar is off', (tester) async {
    final r = await _pump(tester, markdown: 'text', readOnly: true);
    await _focus(tester);
    await tester.typeImeText('x');
    await tester.pump();
    expect(r.md, 'text');
    expect(
      tester.widget<ShadToggle>(_key('markdown.composer.bold')).enabled,
      isFalse,
    );
  });

  testWidgets('Given a narrow field (360 px dialog) then the toolbar wraps '
      'without overflowing', (tester) async {
    await _pump(tester, width: 220);
    expect(tester.takeException(), isNull);
    final bold = tester.getTopLeft(_key('markdown.composer.bold'));
    final block = tester.getTopLeft(_key('markdown.composer.quote'));
    expect(block.dy, greaterThan(bold.dy));
  });

  testWidgets('Given a comment field then the quote button is hidden', (
    tester,
  ) async {
    await _pump(tester, features: MarkdownBlockFeatures.comment);
    expect(_key('markdown.composer.quote'), findsNothing);
    expect(_key('markdown.composer.bullets'), findsOneWidget);
  });

  group('Given a focused field with a caret', () {
    final caret = find.byType(CaretDocumentOverlay);

    for (final b in Brightness.values) {
      testWidgets('in ${b.name} when the focus moves on then the caret is '
          'gone, and it is back when the field is focused again', (
        tester,
      ) async {
        final r = await _pump(tester, markdown: 'text', brightness: b);
        await _focus(tester);
        expect(caret, findsOneWidget);
        final shown = tester.state<CaretDocumentOverlayState>(caret);
        expect(shown.isCaretVisible, isTrue);

        r.focus.requestFocus();
        await tester.pump();
        expect(caret, findsNothing);
        // Unmounted, not just unlisted: a dropped layer that stays mounted
        // keeps painting and blinking.
        expect(shown.mounted, isFalse);
        // The selection is kept for the toolbar; only the caret goes.
        expect(r.controller.selection, isNotNull);

        await _focus(tester);
        expect(caret, findsOneWidget);
      });
    }

    testWidgets('when Tab moves the focus out then the caret is gone', (
      tester,
    ) async {
      final r = await _pump(tester, markdown: 'text');
      await _focus(tester);
      final shown = tester.state<CaretDocumentOverlayState>(caret);
      await tester.pressTab();
      await tester.pump();
      expect(r.focus.hasFocus, isTrue);
      expect(caret, findsNothing);
      expect(shown.mounted, isFalse);
    });

    testWidgets('when the user clicks outside then the field is left and the '
        'caret is gone; a click on its toolbar keeps it', (tester) async {
      final r = await _pump(tester, markdown: 'text');
      await _focus(tester);
      await tester.tap(_key('markdown.composer.bold'));
      await tester.pump();
      expect(caret, findsOneWidget);

      final shown = tester.state<CaretDocumentOverlayState>(caret);
      await tester.tapAt(const Offset(700, 500));
      await tester.pump();
      expect(caret, findsNothing);
      expect(shown.mounted, isFalse);
      expect(r.controller.selection, isNotNull);
      await settleTooltips(tester);
    });

    testWidgets('when the field is read-only then it has no caret', (
      tester,
    ) async {
      await _pump(tester, markdown: 'text', readOnly: true);
      await _focus(tester);
      expect(caret, findsNothing);
    });
  });

  testWidgets('Given enterMarkdown then the field holds the text', (
    tester,
  ) async {
    final r = await _pump(tester);
    await enterMarkdown(tester, _key('markdown.composer'), '**done**');
    expect(r.md, '**done**');
    expect(find.text('done', findRichText: true), findsOneWidget);
  });

  group('Given a click into the field', () {
    for (final (where, dy) in [
      ('below the text', -8.0),
      ('on the text', 0.0),
    ]) {
      testWidgets('when it lands $where and keys follow without a frame '
          'between then the IME is open and the keys land', (tester) async {
        final r = await _pump(tester);
        // The focus is elsewhere first (a dialog's autofocused title).
        r.focus.requestFocus();
        await tester.pump();
        final field = tester.getRect(_key('markdown.composer'));
        final at = dy == 0
            ? Offset(field.left + 20, field.top + 14)
            : Offset(field.center.dx, field.bottom + dy);
        tester.testTextInput.log.clear();
        await tester.tapAt(at, kind: PointerDeviceKind.mouse);
        // No pump: on the web the browser delivers the keys right away.
        expect(
          tester.testTextInput.log.map((c) => c.method),
          containsAll(['TextInput.setClient', 'TextInput.show']),
        );
        expect(
          richEditorStateOf(
            tester,
            _key('markdown.composer'),
          ).focusNode.hasPrimaryFocus,
          isTrue,
        );
        await tester.typeImeText('hi');
        await tester.pump();
        expect(r.md, 'hi');
      });
    }
  });

  group('Given the clipboard', () {
    testWidgets('when a selection is copied then the clipboard holds its '
        'Markdown, and pasting it gives the same content', (tester) async {
      final r = await _pump(tester, markdown: '# Plan\n\n- **one**\n- two');
      _mockClipboard(tester);
      await _focus(tester);
      r.controller.selectAll();
      await tester.pump();
      await _chord(tester, LogicalKeyboardKey.keyC);
      expect(_clipboard(), '# Plan\n\n- **one**\n- two');
      expect(r.md, '# Plan\n\n- **one**\n- two', reason: 'copy keeps it');
      r.controller.markdown = '';
      await tester.pump();
      await _chord(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(r.md, '# Plan\n\n- **one**\n- two');
    });

    testWidgets('when part of a line is cut then its inline Markdown is on '
        'the clipboard and the text is gone', (tester) async {
      final r = await _pump(tester, markdown: 'say *hello* world');
      _mockClipboard(tester);
      await _focus(tester);
      _select(r.controller, 0, 4, 9);
      await tester.pump();
      await _chord(tester, LogicalKeyboardKey.keyX);
      expect(_clipboard(), '*hello*');
      expect(r.md, 'say  world');
      await _chord(tester, LogicalKeyboardKey.keyZ);
      expect(r.md, 'say *hello* world');
    });

    testWidgets('when plain text from another app is pasted then it is '
        'inserted (Markdown in it converted)', (tester) async {
      final r = await _pump(tester, markdown: 'say');
      _mockClipboard(tester, 'plain *words*\nnext line');
      await _focus(tester);
      await _chord(tester, LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(r.md, 'sayplain *words*\nnext line');
    });
  });

  group('Given a spell checker', () {
    testWidgets('when the text has misspelled words then they are '
        'underlined, but not in inline code or literal blocks', (tester) async {
      final checker = _Checker();
      addTearDown(checker.dispose);
      final r = await _pump(
        tester,
        markdown: 'say helo `wrold`\n\n```\nhelo\n```',
        spellChecker: checker,
      );
      await tester.pump();
      final spelling = richEditorStateOf(
        tester,
        _key('markdown.composer'),
      ).spelling!;
      final p = r.controller.document.first.id;
      expect(spelling.errorsOf(p), [const SpellRange(4, 8, 'helo')]);
      expect(spelling.errorsOf(r.controller.document.last.id), isEmpty);
      checker.underline = false;
      checker.notifyListeners();
      await tester.pump();
      expect(spelling.errorsOf(p), isEmpty);
    });

    testWidgets('when a misspelled word is right-clicked then the menu '
        'offers suggestions; one corrects it as one undo step', (tester) async {
      final checker = _Checker();
      addTearDown(checker.dispose);
      final r = await _pump(
        tester,
        markdown: 'say **helo** world',
        spellChecker: checker,
      );
      await _focus(tester);
      await tester.pump();
      await tester.tapAt(
        richTextCenter(tester, _key('markdown.composer'), 4, 8),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(_key('menu.markdown.spell.suggestion.1'), findsOneWidget);
      expect(_key('menu.markdown.copy'), findsOneWidget);
      await tester.tap(_key('menu.markdown.spell.suggestion.0'));
      await tester.pumpAndSettle();
      expect(r.md, 'say **hello** world');
      await _chord(tester, LogicalKeyboardKey.keyZ);
      expect(r.md, 'say **helo** world');
    });

    testWidgets('when Ignore or Add to dictionary is picked then the word is '
        'no longer flagged', (tester) async {
      final checker = _Checker();
      addTearDown(checker.dispose);
      final r = await _pump(
        tester,
        markdown: 'helo wrold',
        spellChecker: checker,
      );
      await tester.pump();
      final spelling = richEditorStateOf(
        tester,
        _key('markdown.composer'),
      ).spelling!;
      final id = r.controller.document.first.id;
      expect(spelling.errorsOf(id), hasLength(2));
      Future<void> pick(int start, int end, String item) async {
        await tester.tapAt(
          richTextCenter(tester, _key('markdown.composer'), start, end),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        await tester.tap(_key('menu.markdown.spell.$item'));
        await tester.pumpAndSettle();
      }

      await pick(0, 4, 'ignore');
      expect(checker.ignored, {'helo'});
      expect(spelling.errorsOf(id), [const SpellRange(5, 10, 'wrold')]);
      await pick(5, 10, 'add');
      expect(checker.added, ['wrold']);
      expect(spelling.errorsOf(id), isEmpty);
      expect(r.md, 'helo wrold');
    });
  });
}
