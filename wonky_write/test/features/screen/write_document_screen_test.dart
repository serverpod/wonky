import 'dart:convert';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:super_editor/super_editor.dart'
    show
        ChangeSelectionRequest,
        DocumentPosition,
        DocumentSelection,
        SelectionChangeType,
        SelectionReason,
        StandardEditables,
        SuperReader,
        TextNode;
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write/config/write_app_config.dart';
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart'
    show EditorMode, LayoutMode;
import 'package:wonky_write/features/screen/write_document_screen.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

void main() {
  late FakeDocumentServer server;
  late CommandTestHarness h;
  late WriteDocumentSession session;
  late SimpleConnectionKeeper keeper;

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
    bool dark = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      Provider<ShellServices>.value(
        value: h.services,
        child: ShadApp(
          theme: dark ? WonkyTheme.dark() : WonkyTheme.light(),
          localizationsDelegates: const [
            WonkyAppLocalizations.delegate,
            WonkyUiLocalizations.delegate,
          ],
          home: Material(
            type: MaterialType.transparency,
            child: WonkyThemeScope(
              data: const WonkyThemeExtension(),
              child: WriteDocumentScreen(
                services: h.services,
                itemUuid: itemUuid,
                themes: WriteThemeCatalog(),
                sessionFactory: (s, uuid) => session,
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
      if (session.phase.value == WriteSessionPhase.ready && i > 10) break;
    }
    // Derived data (word count) is debounced.
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUp(() {
    server = FakeDocumentServer(
      initial: const MarkdownCodec()
          .importMarkdown('# Plan\n\nHello world\n\n## Budget\n\nMoney\n')
          .delta,
    );
    h = CommandTestHarness(
      config: const WriteAppConfig(),
      comments: FakeComments(),
    );
    h.drive.seed(name: 'Plan', uuid: UuidValue.fromString(itemUuid));
    keeper = SimpleConnectionKeeper(minDelay: Duration.zero);
    session = WriteDocumentSession(
      services: h.services,
      itemUuid: itemUuid,
      api: FakeWriteApi(server),
      keeper: keeper,
    );
  });

  tearDown(() async {
    // Let the screen's disposal (undo stack close, stream cancels) settle
    // before the services go away.
    await pumpEventQueue();
    keeper.dispose();
    await pumpEventQueue();
    await h.dispose();
  });

  testWidgets('Given an open document when the screen loads then the '
      'header, menubar, toolbar and canvas render, and the word count bar '
      'shows only once it is turned on', (tester) async {
    await pumpScreen(tester);

    expect(session.phase.value, WriteSessionPhase.ready);
    for (final menu in ['File', 'Edit', 'View', 'Insert', 'Format', 'Tools']) {
      expect(find.text(menu), findsWidgets);
    }
    expect(find.byKey(const ValueKey('write.toolbar.style')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('write.toolbar.modeSwitcher')),
      findsOneWidget,
    );
    expect(find.byType(StatusBar), findsNothing);

    await tester.runAsync(
      () =>
          h.invoke('write.view.toggleWordCount', const {}, InvocationSource.ui),
    );
    await tester.pump();
    expect(find.byType(StatusBar), findsOneWidget);
    expect(
      find.byKey(const ValueKey('write.status.wordCount')),
      findsOneWidget,
    );
    expect(find.textContaining('5 words'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  for (final width in [760.0, 1024.0]) {
    for (final dark in [false, true]) {
      testWidgets('Given a ${width.toInt()} px wide ${dark ? 'dark' : 'light'} '
          'window when the screen loads then nothing overflows', (
        tester,
      ) async {
        await pumpScreen(tester, size: Size(width, 760), dark: dark);

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }
  }

  testWidgets('Given the mode line under the toolbar then it is gray in '
      'editing and green across the whole window while suggesting', (
    tester,
  ) async {
    await pumpScreen(tester);
    final line = find.byKey(const ValueKey('write.canvas.modeLine'));
    expect(line, findsOneWidget);
    expect(tester.getSize(line).width, 1440);
    await h.invoke('write.mode.set', {'mode': 'suggesting'});
    session.editor.applyLocal(
      Delta()
        ..retain(5)
        ..insert('ned'),
      label: 'Typing',
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
    }

    final cue = find.byKey(const ValueKey('write.canvas.suggestingCue'));
    final margin = find.byKey(const ValueKey('write.commentMargin')).first;
    expect(cue, findsOneWidget);
    expect(margin, findsOneWidget);
    expect(tester.getSize(cue).width, 1440);
    expect(line, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Given a suggestion card in the margin when toggling comments '
      'then the margin hides and shows again (no comments side panel)', (
    tester,
  ) async {
    await pumpScreen(tester);
    await h.invoke('write.mode.set', {'mode': 'suggesting'});
    session.editor.applyLocal(
      Delta()
        ..retain(5)
        ..insert('ned'),
      label: 'Typing',
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
    }
    final margin = find.byKey(const ValueKey('write.commentMargin'));
    expect(margin, findsWidgets);
    // No Open / For you filter in the margin.
    expect(find.byKey(const ValueKey('comments.filter.open')), findsNothing);

    await tester.runAsync(
      () =>
          h.invoke('shell.comments.togglePanel', const {}, InvocationSource.ui),
    );
    await tester.pump();
    expect(margin, findsNothing);
    expect(find.byType(CommentsPanel), findsNothing);

    await tester.runAsync(
      () =>
          h.invoke('shell.comments.togglePanel', const {}, InvocationSource.ui),
    );
    await tester.pump();
    expect(margin, findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Given a selection when starting a comment then the composer '
      'is a margin card, and ending the draft removes it without errors', (
    tester,
  ) async {
    await pumpScreen(tester);
    session.editor.select(const DeltaSelection(8, 13));
    await tester.runAsync(
      () => h.invoke('shell.comments.create', const {}, InvocationSource.ui),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
    }
    final draft = find.byKey(const ValueKey('write.margin.draft'));
    expect(draft, findsOneWidget);
    expect(h.services.commentsHost?.isShown, isTrue);

    h.services.comments.value!.cancelDraft();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(draft, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Given a comment on the whole document then it is a card at '
      'the top of the margin', (tester) async {
    await pumpScreen(tester);
    await tester.runAsync(
      () => h.invoke('shell.comments.create', const {
        'body': 'Looks good overall',
        'anchorKind': 'document',
        'anchorJson': '{"v":1}',
      }, InvocationSource.ui),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Looks good overall'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('write.commentMargin')).first,
        matching: find.text('Looks good overall'),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Given a suggestion card and a window with room for both then '
      'the page moves left of the comment margin', (tester) async {
    await pumpScreen(tester, size: const Size(1240, 900));
    await h.invoke('write.mode.set', {'mode': 'suggesting'});
    session.editor.applyLocal(
      Delta()
        ..retain(5)
        ..insert('ned'),
      label: 'Typing',
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
    }

    final page = tester.getRect(find.byKey(const ValueKey('write.page')));
    final margin = tester.getRect(
      find.byKey(const ValueKey('write.commentMargin')).first,
    );
    expect(page.right, lessThanOrEqualTo(margin.left));

    // Too narrow for both: the page moves to the left gutter, so the margin
    // covers at most the page's right margin, not its text.
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.physicalSize = const Size(1100, 900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final narrowPage = tester.getRect(find.byKey(const ValueKey('write.page')));
    final narrowMargin = tester.getRect(
      find.byKey(const ValueKey('write.commentMargin')).first,
    );
    final canvasLeft = tester.getTopLeft(find.byType(WonkyEditor)).dx;
    expect(narrowPage.left - canvasLeft, closeTo(8, 0.5));
    final textRight =
        narrowPage.right - session.editor.view.pageSetup.margins.right;
    expect(textRight, lessThanOrEqualTo(narrowMargin.left));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Given the toolbar then the comments toggle sits before the '
      'mode switcher, the title row has none, and it toggles the margin', (
    tester,
  ) async {
    await pumpScreen(tester);
    final toggle = find.byKey(const ValueKey('write.toolbar.comments'));
    final mode = find.byKey(const ValueKey('write.toolbar.modeSwitcher'));
    expect(toggle, findsOneWidget);
    expect(find.byKey(const ValueKey('editor.comments')), findsNothing);
    expect(tester.getCenter(toggle).dx, lessThan(tester.getCenter(mode).dx));
    // Some space between the two buttons.
    expect(
      tester.getRect(mode).left - tester.getRect(toggle).right,
      greaterThanOrEqualTo(6),
    );
    expect(h.services.commentsHost!.isShown, isTrue);

    await tester.tap(toggle);
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    expect(h.services.commentsHost!.isShown, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Given the screen when it loads then the panels are icons in '
      'the rail, and the title row has no history or assistant buttons', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('panel.rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('panel.rail.outline')), findsOneWidget);
    expect(find.byKey(const ValueKey('panel.rail.find')), findsOneWidget);
    // File › Details is not in the rail.
    expect(find.byKey(const ValueKey('panel.rail.details')), findsNothing);
    expect(find.byKey(const ValueKey('editor.history')), findsNothing);
    expect(find.byKey(const ValueKey('editor.assistant')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('panel.rail.outline')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('panel.collapse')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Given the screen when toggling the outline then the panel lists '
      'the headings', (tester) async {
    await pumpScreen(tester);

    await tester.runAsync(
      () => h.invoke('write.view.toggleOutline', const {}, InvocationSource.ui),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(pumpEventQueue);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('outline.item.0')), findsOneWidget);
    expect(find.byKey(const ValueKey('outline.item.1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Given the screen when opening find then the find panel shows '
      'and highlights matches', (tester) async {
    await pumpScreen(tester);

    await tester.runAsync(
      () => h.invoke('write.find.open', const {
        'query': 'world',
      }, InvocationSource.ui),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('find.query')), findsOneWidget);
    expect(session.editor.view.findMatches, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  for (final (width, dark) in const [
    (768.0, true),
    (1024.0, false),
    (1440.0, true),
  ]) {
    testWidgets(
      'Given a ${width.toInt()} px window in ${dark ? 'dark' : 'light'} '
      'mode when the screen renders then nothing overflows',
      (tester) async {
        await pumpScreen(tester, size: Size(width, 900), dark: dark);

        expect(
          find.byKey(const ValueKey('write.toolbar.modeSwitcher')),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  group('Given a new document (T-1)', () {
    for (final (name, layout) in [
      ('the page setup the server gives new documents', 'pageless'),
      ('a user default of Pages', 'pages'),
    ]) {
      testWidgets(
        'when it opens with $name then it shows ${layout == 'pageless' ? 'Pageless' : 'Pages'}',
        (tester) async {
          // What `DriveService.newDocumentPageSetup` stores.
          server.meta = DocumentMetaView(
            pageSetupJson: jsonEncode(
              PageSetup.defaultsFor('en').toJson()..['layout'] = layout,
            ),
          );
          await pumpScreen(tester);

          final pageless = layout == 'pageless';
          expect(
            session.editor.view.layout,
            pageless ? LayoutMode.pageless : LayoutMode.pages,
          );
          expect(
            find.byKey(const ValueKey('write.page')),
            pageless ? findsNothing : findsOneWidget,
          );
          // The rest of the page setup is the locale default.
          expect(session.editor.view.pageSetup.margins.left, 96);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        },
      );
    }
  });

  group('Given a narrow (mobile) window', () {
    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    }

    testWidgets('when an editor opens a document then it shows read-only '
        'and scrollable: no menubar, toolbar, mode line, panels or status '
        'bar (suite 02 §6.1)', (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      await tester.pump();

      expect(session.phase.value, WriteSessionPhase.ready);
      expect(find.byKey(const ValueKey('editor.mobile')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('editor.mobile.readOnly')),
        findsOneWidget,
      );
      expect(find.byType(WonkyMenubar), findsNothing);
      expect(find.byType(WonkyToolbar), findsNothing);
      expect(find.byKey(const ValueKey('write.toolbar.style')), findsNothing);
      expect(find.byKey(const ValueKey('write.canvas.modeLine')), findsNothing);
      expect(find.byType(StatusBar), findsNothing);
      expect(find.byType(WonkySplitView), findsNothing);
      expect(find.byKey(const ValueKey('editor.share')), findsNothing);
      // The document, in Viewing, in a scroll view.
      expect(find.byType(WonkyEditor), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(WonkyEditor),
          matching: find.byType(Scrollable),
        ),
        findsWidgets,
      );
      expect(session.readOnlyView, isTrue);
      expect(session.editor.mode, EditorMode.viewing);
      final r = await tester.runAsync(
        () => h.invoke('write.mode.set', const {
          'mode': 'editing',
        }, InvocationSource.ui),
      );
      expect(r!.isOk, isFalse);
      expect(session.editor.mode, EditorMode.viewing);
      await close(tester);
    });

    testWidgets('when the window becomes wide then the editor, its toolbar '
        'and Editing return (the desktop is unchanged)', (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      await tester.pump();
      expect(session.editor.mode, EditorMode.viewing);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('editor.mobile')), findsNothing);
      expect(find.byKey(const ValueKey('write.toolbar.style')), findsOneWidget);
      expect(session.readOnlyView, isFalse);
      expect(session.editor.mode, EditorMode.editing);
      await close(tester);
    });

    /// The left inset of the text in the editor canvas.
    double textInset(WidgetTester tester) =>
        tester.getTopLeft(find.text('Hello world', findRichText: true)).dx -
        tester.getTopLeft(find.byType(WonkyEditor)).dx;

    testWidgets('when a Pages document opens then it shows Pageless, and '
        'Pages again once the window is wide; the page setup is unchanged '
        '(T-1)', (tester) async {
      // The fake server's document has the default page setup: Pages.
      await pumpScreen(tester, size: const Size(390, 844));
      await tester.pump();

      expect(session.meta.value.pageSetup.layout, PageLayoutMode.pages);
      expect(session.editor.view.layout, LayoutMode.pageless);
      expect(find.byKey(const ValueKey('write.page')), findsNothing);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pump();
      await tester.pump();
      expect(session.editor.view.layout, LayoutMode.pages);
      expect(find.byKey(const ValueKey('write.page')), findsOneWidget);
      await close(tester);
    });

    testWidgets('when the document shows then the text has 16 px beside and '
        'above it instead of the margins (T-12, T-1)', (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final editor = tester.widget<WonkyEditor>(find.byType(WonkyEditor));
      expect(editor.compactPadding, WriteDocumentScreen.mobileTextPadding);
      expect(textInset(tester), closeTo(16, 1));
      // The first block (the title) starts 16 px below the separator, not
      // the pageless 48 px.
      final top =
          tester
              .getTopLeft(
                find.descendant(
                  of: find.byType(WonkyEditor),
                  matching: find.text('Plan', findRichText: true),
                ),
              )
              .dy -
          tester.getTopLeft(find.byType(WonkyEditor)).dy;
      expect(top, lessThan(24));
      // Below the last block: 16 px instead of the pageless 96 px.
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(WonkyEditor),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final viewport = tester.getSize(find.byType(WonkyEditor)).height;
      final position = scrollable.position;
      final contentHeight = position.maxScrollExtent + viewport;
      final lastBottom =
          tester.getBottomLeft(find.text('Money', findRichText: true)).dy -
          tester.getTopLeft(find.byType(WonkyEditor)).dy;
      if (position.maxScrollExtent > 0) {
        expect(contentHeight - lastBottom, lessThan(40));
      }
      await close(tester);
    });

    for (final dark in [false, true]) {
      testWidgets('when the document shows in ${dark ? 'dark' : 'light'} '
          'then a 1 px border line separates the title row from the page '
          '(T-1)', (tester) async {
        await pumpScreen(tester, size: const Size(390, 844), dark: dark);
        await tester.pump();

        final line = find.byKey(const ValueKey('write.mobile.separator'));
        expect(line, findsOneWidget);
        expect(tester.getSize(line).height, 1);
        final color = tester
            .widget<ColoredBox>(
              find.descendant(of: line, matching: find.byType(ColoredBox)),
            )
            .color;
        final theme = dark ? WonkyTheme.dark() : WonkyTheme.light();
        expect(color, theme.colorScheme.border);
        // Right below the title row, above the page.
        expect(
          tester.getTopLeft(line).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(WonkyEditor)).dy),
        );
        await close(tester);
      });
    }

    testWidgets('when the user double-taps or long-presses a word then no '
        'text is selected (T-1)', (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      await tester.pump();
      expect(session.editor.selectable, isFalse);

      final word = tester.getCenter(
        find.text('Hello world', findRichText: true),
      );
      await tester.tapAt(word);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(word);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.longPressAt(word);
      await tester.pump(const Duration(milliseconds: 400));

      // Nothing is selected: at most a collapsed position, which a
      // read-only document doesn't show.
      final reader = tester.widget<SuperReader>(find.byType(SuperReader));
      expect(reader.editor.composer.selection?.isCollapsed ?? true, isTrue);
      expect(session.editor.selection?.isCollapsed ?? true, isTrue);
      expect(tester.takeException(), isNull);

      // What the reader's gestures ask for (a word, a drag) is collapsed.
      final node = reader.editor.document.first as TextNode;
      reader.editor.execute([
        ChangeSelectionRequest(
          DocumentSelection(
            base: DocumentPosition(
              nodeId: node.id,
              nodePosition: node.beginningPosition,
            ),
            extent: DocumentPosition(
              nodeId: node.id,
              nodePosition: node.endPosition,
            ),
          ),
          SelectionChangeType.expandSelection,
          SelectionReason.userInteraction,
        ),
      ]);
      await tester.pump();
      expect(reader.editor.composer.selection!.isCollapsed, isTrue);
      expect(
        reader.editor.composer.selection!.extent.nodePosition,
        node.endPosition,
      );

      // The desktop selects again.
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pump();
      await tester.pump();
      expect(session.editor.selectable, isTrue);
      await close(tester);
    });

    testWidgets('when the window is wide then the page keeps its margins and '
        'width (the desktop is unchanged)', (tester) async {
      await pumpScreen(tester);
      session.editor.view.layout = LayoutMode.pages;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final editor = tester.widget<WonkyEditor>(find.byType(WonkyEditor));
      expect(editor.compactPadding, isNull);
      final page = tester.getRect(find.byKey(const ValueKey('write.page')));
      final setup = session.editor.view.pageSetup;
      expect(
        page.width,
        closeTo(setup.size.width * session.editor.view.zoom, 1),
      );
      expect(
        tester.getTopLeft(find.text('Hello world', findRichText: true)).dx -
            page.left,
        closeTo(setup.margins.left * session.editor.view.zoom, 1),
      );
      await close(tester);
    });

    for (final dark in [false, true]) {
      testWidgets('when the screen renders at 360 px in '
          '${dark ? 'dark' : 'light'} then nothing overflows', (tester) async {
        await pumpScreen(tester, size: const Size(360, 640), dark: dark);
        await tester.pump();
        expect(find.byKey(const ValueKey('editor.mobile')), findsOneWidget);
        await close(tester);
      });
    }
  });
}
