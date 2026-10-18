import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, DriveItemView;
import 'package:wonky_core/wonky_core.dart'
    show CommandStatus, InvocationSource;
import 'package:wonky_ui/testing.dart';
import 'package:wonky_write/features/editor/model/link_url_policy.dart';
import 'package:wonky_write/features/links/link_editor.dart';
import 'package:wonky_write/features/screen/anchored_popover.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaSelection, OutlineEntry;

import '../screen/support/screen_harness.dart';
import '../screen/support/shad_fonts.dart';

const _open = ValueKey<String>('test.open');
const _popover = ValueKey<String>('write.popover.link');
const _url = ValueKey<String>('write.popover.link.url');
const _text = ValueKey<String>('write.popover.link.text');
const _apply = ValueKey<String>('write.popover.link.apply');
const _remove = ValueKey<String>('write.popover.link.remove');
const _error = ValueKey<String>('write.popover.link.error');

const _docUuid = '00000000-0000-7000-8000-0000000000d1';

OutlineEntry _heading(int index, int level, String text, String anchor) =>
    OutlineEntry(
      index: index,
      level: level,
      text: text,
      lineIndex: index * 2,
      deltaOffset: index * 20,
      sectionStart: index * 20,
      sectionLength: 20,
      anchorId: anchor,
    );

final _headings = [
  _heading(0, 1, 'Plan', 'h-plan-1'),
  _heading(1, 2, 'Budget', 'h-budget-1'),
  _heading(2, 2, 'Timeline', 'h-timeline-1'),
];

/// What the popover returned once it closed.
class _Closed {
  bool closed = false;
  LinkEdit? value;
}

Future<_Closed> _openEditor(
  WidgetTester tester, {
  String? initialUrl,
  String? initialText = 'world',
  bool showText = true,
  List<OutlineEntry>? headings,
  Future<List<DriveItemView>> Function(String query)? searchDocuments,
  Brightness brightness = Brightness.light,
}) async {
  final closed = _Closed();
  await pumpWonky(
    tester,
    Builder(
      builder: (context) => ShadButton(
        key: _open,
        onPressed: () => unawaited(
          showAnchoredPopover<LinkEdit>(
            context,
            anchor: const Rect.fromLTWH(200, 100, 1, 1),
            width: 380,
            builder: (_) => LinkEditor(
              policy: const LinkUrlPolicy(documentUuid: _docUuid),
              headings: headings ?? _headings,
              initialUrl: initialUrl,
              initialText: initialText,
              showText: showText,
              // The app always passes a drive search (offline: no hits).
              searchDocuments: searchDocuments ?? (_) async => const [],
            ),
          ).then((v) {
            closed
              ..closed = true
              ..value = v;
          }),
        ),
        child: const Text('Open'),
      ),
    ),
    brightness: brightness,
  );
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
  return closed;
}

Future<void> _typeUrl(WidgetTester tester, String url) async {
  await tester.enterText(find.byKey(_url), url);
  await tester.pump();
}

Future<void> _tapApply(WidgetTester tester) async {
  await tester.tap(find.byKey(_apply));
  await tester.pumpAndSettle();
}

String _urlText(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(_url),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

Matcher _applies(String url, {String? text}) => isA<ApplyLink>()
    .having((a) => a.url, 'url', url)
    .having((a) => a.text, 'text', text);

void main() {
  setUpAll(loadShadFonts);

  for (final brightness in Brightness.values) {
    group('Given the link editor for a new link (${brightness.name})', () {
      testWidgets('when it opens then the fields and the heading suggestions '
          'show, Apply is disabled and there is no Remove', (tester) async {
        await _openEditor(tester, brightness: brightness);

        expect(find.byKey(_popover), findsOneWidget);
        expect(find.byKey(_text), findsOneWidget);
        expect(tester.widget<ShadButton>(find.byKey(_apply)).enabled, isFalse);
        expect(find.byKey(_remove), findsNothing);
        expect(find.text('Budget'), findsOneWidget);
        expect(find.text('Heading 2'), findsNWidgets(2));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });
    });
  }

  group('Given the link editor for a new link', () {
    testWidgets('when typing a domain and pressing Apply then an https link '
        'is returned without changing the text', (tester) async {
      final closed = await _openEditor(tester);

      await _typeUrl(tester, 'example.com');
      expect(tester.widget<ShadButton>(find.byKey(_apply)).enabled, isTrue);
      await _tapApply(tester);

      expect(closed.closed, isTrue);
      expect(closed.value, _applies('https://example.com'));
    });

    testWidgets('when changing the text then the new text is returned', (
      tester,
    ) async {
      final closed = await _openEditor(tester);

      await tester.enterText(find.byKey(_text), 'the world');
      await _typeUrl(tester, 'https://example.com/');
      await _tapApply(tester);

      expect(closed.value, _applies('https://example.com/', text: 'the world'));
    });

    testWidgets('when submitting something that is not a link then an error '
        'shows and typing again clears it', (tester) async {
      final closed = await _openEditor(tester);

      await _typeUrl(tester, 'not a link');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(closed.closed, isFalse);
      expect(find.byKey(_error), findsOneWidget);
      expect(find.text("This doesn't look like a link"), findsOneWidget);

      await _typeUrl(tester, 'example.org');
      expect(find.byKey(_error), findsNothing);
    });

    testWidgets('when filtering the headings and tapping one then a link to '
        'that heading is returned', (tester) async {
      final closed = await _openEditor(tester);

      await _typeUrl(tester, '#time');
      expect(find.text('Budget'), findsNothing);
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();

      expect(closed.value, _applies('wonky://doc/$_docUuid#h-timeline-1'));
    });

    testWidgets('when moving down the suggestions with the arrow keys and '
        'pressing Enter then the highlighted heading is linked', (
      tester,
    ) async {
      final closed = await _openEditor(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(closed.value, _applies('wonky://doc/$_docUuid#h-budget-1'));
    });

    testWidgets('when typing an email address then a mailto link is '
        'returned', (tester) async {
      final closed = await _openEditor(tester);

      await _typeUrl(tester, 'ana@example.com');
      await _tapApply(tester);

      expect(closed.value, _applies('mailto:ana@example.com'));
    });

    testWidgets(
      'when pasting a web address then the heading suggestions hide',
      (tester) async {
        await _openEditor(tester);
        expect(find.text('Budget'), findsOneWidget);

        await _typeUrl(tester, 'https://example.com/');

        expect(find.text('Budget'), findsNothing);
      },
    );

    testWidgets('when the selection spans blocks then only the link field '
        'shows', (tester) async {
      await _openEditor(tester, showText: false);

      expect(find.byKey(_text), findsNothing);
      expect(find.byKey(_url), findsOneWidget);
    });

    testWidgets('when pressing Cancel then nothing is returned', (
      tester,
    ) async {
      final closed = await _openEditor(tester);

      await _typeUrl(tester, 'example.com');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(closed.closed, isTrue);
      expect(closed.value, isNull);
    });
  });

  group('Given the link editor with drive search', () {
    late CommandTestHarness shell;

    setUp(() {
      shell = CommandTestHarness();
      shell.drive.seed(name: 'Plan for Q3');
      shell.drive.seed(name: 'Plans', kind: DriveItemKind.folder);
    });
    tearDown(() => shell.dispose());

    testWidgets('when typing a name then matching documents are suggested '
        'and tapping one links to it', (tester) async {
      final doc = shell.drive.seed(name: 'Planning notes');
      final closed = await _openEditor(
        tester,
        headings: const [],
        searchDocuments: LinkEditor.driveSearch(shell.services),
      );

      await _typeUrl(tester, 'planning');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(find.text('Planning notes'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      await tester.tap(find.text('Planning notes'));
      await tester.pumpAndSettle();

      expect(closed.value, _applies('wonky://doc/${doc.uuid.uuid}'));
    });

    testWidgets('when the search matches a folder then only documents are '
        'suggested', (tester) async {
      await _openEditor(
        tester,
        headings: const [],
        searchDocuments: LinkEditor.driveSearch(shell.services),
      );

      await _typeUrl(tester, 'plan');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(find.text('Plan for Q3'), findsOneWidget);
      expect(find.text('Plans'), findsNothing);
    });

    testWidgets('when typing a domain then the drive is not searched', (
      tester,
    ) async {
      final queries = <String>[];
      await _openEditor(
        tester,
        headings: const [],
        searchDocuments: (q) async {
          queries.add(q);
          return const [];
        },
      );

      await _typeUrl(tester, 'plan.example');
      await tester.pump(const Duration(milliseconds: 250));
      await _typeUrl(tester, 'pl');
      await tester.pump(const Duration(milliseconds: 250));

      expect(queries, ['pl']);
    });
  });

  group('Given the link editor on an existing link', () {
    testWidgets('when it opens then Remove shows and Remove returns a '
        'removal', (tester) async {
      final closed = await _openEditor(tester, initialUrl: 'https://a.test/');

      expect(_urlText(tester), 'https://a.test/');
      await tester.tap(find.byKey(_remove));
      await tester.pumpAndSettle();

      expect(closed.value, isA<RemoveLink>());
    });

    testWidgets('when it links to a heading of this document then the field '
        'shows the short #anchor form', (tester) async {
      await _openEditor(tester, initialUrl: 'wonky://doc/$_docUuid#h-budget-1');

      expect(_urlText(tester), '#h-budget-1');
    });
  });

  group('Given "Hello world" with "world" selected and write.link.insert', () {
    testWidgets('when applying a link then the selection is linked and undo '
        'removes it', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: 'Hello world\n');
      late BuildContext context;
      await h.pump(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      );
      h.doc.editor.select(const DeltaSelection(6, 11));

      final result = h.services.dispatcher.invoke(
        'write.link.insert',
        source: InvocationSource.ui,
        context: context,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_popover), findsOneWidget);
      await _typeUrl(tester, 'https://example.com/');
      await _tapApply(tester);

      expect((await result).isOk, isTrue);
      final linked = h.doc.editor.delta.toList().where(
        (op) => op.attributes?['link'] == 'https://example.com/',
      );
      expect(linked.map((op) => op.data), ['world']);

      await tester.runAsync(h.session.undo.undo);
      expect(
        h.doc.editor.delta.toList().where(
          (op) => op.attributes?['link'] != null,
        ),
        isEmpty,
      );
      await h.dispose(tester);
    });

    testWidgets('when cancelling then the document is unchanged', (
      tester,
    ) async {
      final h = await ScreenHarness.open(tester, markdown: 'Hello world\n');
      late BuildContext context;
      await h.pump(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      );
      h.doc.editor.select(const DeltaSelection(6, 11));
      final before = h.doc.editor.delta;

      final result = h.services.dispatcher.invoke(
        'write.link.insert',
        source: InvocationSource.ui,
        context: context,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect((await result).status, CommandStatus.cancelled);
      expect(h.doc.editor.delta, before);
      await h.dispose(tester);
    });
  });
}
