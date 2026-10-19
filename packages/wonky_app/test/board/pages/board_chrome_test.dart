import 'dart:math' as math;
import 'dart:ui' show SemanticsRole, Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' hide BoardPostPage;
import 'package:wonky_ui/testing.dart';

import 'support/board_pump.dart';

/// The board's chrome (specs/16 §4.3–4.4): the breadcrumb and its trail
/// rules, the actions in the top bar, and the tabs bar with count badges.
void main() {
  BoardTest? current;
  BoardTest t() => current!;
  tearDown(() async {
    await current?.dispose();
    current = null;
  });

  /// Wide enough for the whole trail in the test font (every glyph is a
  /// square as wide as the font size).
  const wide = Size(2400, 1000);

  /// #1 an idea in T-1, #2 a bug, #3 an idea similar to #1; T-1 published.
  FakeBoardRepository seeded({bool admin = false}) {
    final b = FakeBoardRepository(isAdmin: admin);
    b.seedPost(title: 'Dark mode for slides', score: 3);
    b.seedPost(title: 'Paste loses styles', kind: BoardPostKind.bug);
    b.seedPost(title: 'Dark mode for sheets');
    b.seedTask(title: 'Sorting by name in Drive', posts: [1]);
    return b;
  }

  /// Records the shell history like the shell's router listener does.
  void recordHistory() {
    final s = t().s;
    s.recordLocation(t().location);
    s.router.routerDelegate.addListener(() => s.recordLocation(t().location));
  }

  /// The visible crumb ids, in order.
  List<String> crumbIds() => [
    for (final id in const [
      'app',
      'root',
      'contribute',
      'list',
      'task',
      'post',
    ])
      if (byKey('board.crumb.$id').evaluate().isNotEmpty) id,
  ];

  String crumbText(String id) {
    final f = find.descendant(
      of: byKey('board.crumb.$id'),
      matching: find.byType(Text),
      matchRoot: true,
    );
    return (f.evaluate().first.widget as Text).data!;
  }

  bool isCurrent(String id) =>
      find
          .ancestor(
            of: byKey('board.crumb.$id'),
            matching: find.byType(FocusableActionDetector),
          )
          .evaluate()
          .isEmpty &&
      byKey('board.crumb.$id').evaluate().single.widget is Text;

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(byKey(key));
    await tester.pumpAndSettle();
  }

  group('Given the breadcrumb', () {
    testWidgets('when a list shows then it is app › Bugs & improvements › '
        'the list, the list current', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/bugs',
        board: seeded(),
        size: wide,
      );

      expect(crumbIds(), ['app', 'root', 'list']);
      expect(crumbText('root'), 'Contribute & build');
      expect(crumbText('list'), 'Bugs');
      expect(isCurrent('list'), isTrue);
      expect(isCurrent('root'), isFalse);
      await settleTooltips(tester);
    });

    testWidgets('when a post opens from a list then the trail is root › '
        'list › post, and the list crumb goes back up', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/bugs',
        board: seeded(),
        size: wide,
      );

      await tap(tester, 'board.row.2');

      expect(t().location, '/improvements/p/2?list=bugs');
      expect(crumbIds(), ['app', 'root', 'list', 'post']);
      expect(crumbText('list'), 'Bugs');
      expect(crumbText('post'), '#2 Paste loses styles');
      expect(isCurrent('post'), isTrue);

      await tap(tester, 'board.crumb.list');
      expect(t().location, '/improvements/bugs');
      await settleTooltips(tester);
    });

    testWidgets('when a task opens from Up for grabs and then its linked '
        'post then the trail is root › Up for grabs › T-1 › #1', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/tasks',
        board: seeded(),
        size: wide,
      );

      await tap(tester, 'board.task.1');
      expect(t().location, '/improvements/t/1?list=tasks');
      expect(crumbIds(), ['app', 'root', 'list', 'task']);
      expect(crumbText('list'), 'Up for grabs');
      expect(crumbText('task'), 'T-1 Sorting by name in Drive');

      await tap(tester, 'board.task.post.1');
      expect(t().location, '/improvements/p/1?list=tasks&task=1');
      expect(crumbIds(), ['app', 'root', 'list', 'task', 'post']);
      expect(crumbText('task'), 'T-1 Sorting by name in Drive');
      expect(crumbText('post'), '#1 Dark mode for slides');
      await settleTooltips(tester);
    });

    testWidgets('when a post under its task opens the task then the trail '
        'truncates to the task, without a new loop in the history', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/tasks',
        board: seeded(),
        size: wide,
      );
      recordHistory();
      await tap(tester, 'board.task.1');
      await tap(tester, 'board.task.post.1');

      await tap(tester, 'board.post.link.task');

      expect(t().location, '/improvements/t/1?list=tasks');
      expect(crumbIds(), ['app', 'root', 'list', 'task']);
      expect(isCurrent('task'), isTrue);
      await settleTooltips(tester);
    });

    testWidgets('when a similar post opens from a post then it replaces the '
        'post in the trail and in the history', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements',
        board: seeded(),
        size: wide,
      );
      recordHistory();
      await tap(tester, 'board.row.3');
      expect(t().location, '/improvements/p/3?list=improvements');
      final depth = t().s.navHistory.length;

      await tap(tester, 'board.post.link.similar.1');

      expect(t().location, '/improvements/p/1?list=improvements');
      expect(crumbIds(), ['app', 'root', 'list', 'post']);
      expect(crumbText('post'), '#1 Dark mode for slides');
      expect(t().s.navHistory.length, depth, reason: 'replaced, not pushed');
      expect(t().s.navHistory.last, '/improvements/p/1?list=improvements');
      expect(
        t().s.navHistory[depth - 2],
        '/improvements',
        reason: 'Back still returns to the list',
      );
      await settleTooltips(tester);
    });

    testWidgets('when a post is opened from a bare link then its list is its '
        'kind (Bugs), and a task\'s is Up for grabs, or Done once done', (
      tester,
    ) async {
      final b = seeded()
        ..seedTask(
          title: 'Finished work',
          posts: [3],
          status: BoardTaskStatus.done,
        );
      current = await pumpBoard(
        tester,
        '/improvements/p/2',
        board: b,
        size: wide,
      );
      expect(crumbIds(), ['app', 'root', 'list', 'post']);
      expect(crumbText('list'), 'Bugs');

      await t().go(tester, '/improvements/p/1');
      expect(crumbText('list'), 'Improvements');

      await t().go(tester, '/improvements/t/1');
      expect(crumbText('list'), 'Up for grabs');

      await t().go(tester, '/improvements/t/2');
      expect(crumbText('list'), 'Done');
      await settleTooltips(tester);
    });

    testWidgets('when the contribute page shows then it is root › How to '
        'contribute', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/contribute',
        board: seeded(),
        size: wide,
      );

      expect(crumbIds(), ['app', 'root', 'contribute']);
      expect(isCurrent('contribute'), isTrue);
      await settleTooltips(tester);
    });

    testWidgets('when a crumb is focused with Tab then Enter follows it', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/p/2?list=bugs',
        board: seeded(),
        size: wide,
      );

      bool rootFocused() {
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) return false;
        var found = false;
        ctx.visitAncestorElements((e) {
          if (e.widget.key == const ValueKey<String>('board.crumb.root')) {
            found = true;
            return false;
          }
          return true;
        });
        return found;
      }

      for (var i = 0; i < 6 && !rootFocused(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(rootFocused(), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(t().location, '/improvements');
      await settleTooltips(tester);
    });

    testWidgets('then it is a navigation landmark named Breadcrumb, the '
        'crumbs are links and the current page is marked current', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      current = await pumpBoard(
        tester,
        '/improvements/p/2?list=bugs',
        board: seeded(),
        size: wide,
      );

      final nav = tester.getSemantics(find.bySemanticsLabel('Breadcrumb'));
      expect(nav.getSemanticsData().role, SemanticsRole.navigation);
      final root = tester.getSemantics(
        find.bySemanticsLabel('Contribute & build'),
      );
      expect(root.flagsCollection.isLink, isTrue);
      final app = tester.getSemantics(
        find.bySemanticsLabel('Close Contribute & build'),
      );
      expect(app.flagsCollection.isLink, isTrue);
      final post = tester.getSemantics(
        find.bySemanticsLabel('#2 Paste loses styles'),
      );
      expect(post.flagsCollection.isSelected, Tristate.isTrue);
      expect(post.flagsCollection.isLink, isFalse);
      await settleTooltips(tester);
      semantics.dispose();
    });

    testWidgets('when the window is narrow then the middle crumbs collapse '
        'into a menu, keeping the app icon and the current page', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/p/1?list=tasks&task=1',
        board: seeded(),
        size: const Size(360, 800),
      );

      expect(tester.takeException(), isNull);
      expect(crumbIds(), ['app', 'post']);
      expect(byKey('board.crumb.more'), findsOneWidget);

      await tap(tester, 'board.crumb.more');
      expect(byKey('board.crumb.menu.root'), findsOneWidget);
      expect(byKey('board.crumb.menu.task'), findsOneWidget);
      await tap(tester, 'board.crumb.menu.list');

      expect(t().location, '/improvements/tasks');
      await settleTooltips(tester);
    });

    testWidgets('when the window is wide then nothing collapses', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/p/1?list=tasks&task=1',
        board: seeded(),
        size: wide,
      );

      expect(crumbIds(), ['app', 'root', 'list', 'task', 'post']);
      expect(byKey('board.crumb.more'), findsNothing);
      await settleTooltips(tester);
    });
  });

  group('Given the top bar', () {
    List<CommandInvoked> listen() {
      final events = <CommandInvoked>[];
      final sub = t().s.dispatcher.events.listen(events.add);
      addTearDown(sub.cancel);
      return events;
    }

    testWidgets('when wide then Report a bug, Suggest an improvement and How '
        'to contribute are outline sm buttons with icons, in the bar', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/p/1',
        board: seeded(),
        size: wide,
      );

      final keys = [
        'board.reportBug',
        'board.suggest',
        'board.howToContribute',
      ];
      double? lastX;
      for (final k in keys) {
        final b = tester.widget<ShadButton>(byKey(k));
        expect(b.variant, ShadButtonVariant.outline, reason: k);
        expect(b.size, ShadButtonSize.sm, reason: k);
        expect(b.leading, isA<Icon>(), reason: k);
        final c = tester.getCenter(byKey(k));
        expect(c.dy, lessThan(56), reason: '$k is in the bar');
        if (lastX != null) expect(c.dx, greaterThan(lastX));
        lastX = c.dx;
      }
      await settleTooltips(tester);
    });

    testWidgets('when signed out then Report and Suggest invoke '
        'shell.board.report with their kind, which goes to sign-in, and Sign '
        'in stays', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/p/1',
        board: seeded(),
        signedIn: false,
      );
      final events = listen();
      expect(byKey('board.signIn'), findsOneWidget);

      await tap(tester, 'board.reportBug');
      expect(events.single.id, 'shell.board.report');
      expect(events.single.args['kind'], 'bug');
      expect(t().location, '/signin?next=%2Fimprovements%2Fp%2F1');

      await t().go(tester, '/improvements');
      await tap(tester, 'board.suggest');
      expect(events.last.id, 'shell.board.report');
      expect(events.last.args['kind'], 'idea');
      await settleTooltips(tester);
    });

    testWidgets('when How to contribute is pressed then it opens, without '
        'its own button there', (tester) async {
      current = await pumpBoard(tester, '/improvements', board: seeded());

      await tap(tester, 'board.howToContribute');

      expect(t().location, '/improvements/contribute');
      expect(byKey('board.howToContribute'), findsNothing);
      expect(byKey('board.reportBug'), findsOneWidget);
      await settleTooltips(tester);
    });

    testWidgets('when medium wide then they are icon buttons with tooltips', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements',
        board: seeded(),
        size: const Size(800, 800),
      );

      for (final k in [
        'board.reportBug',
        'board.suggest',
        'board.howToContribute',
      ]) {
        expect(
          find.ancestor(of: byKey(k), matching: find.byType(ShadTooltip)),
          findsWidgets,
          reason: k,
        );
        expect(tester.widget(byKey(k)), isA<ShadIconButton>(), reason: k);
      }
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
    });

    for (final path in const [
      '/improvements',
      '/improvements/p/1?list=tasks&task=1',
      // The task page's body has wide buttons in the test font (every
      // glyph a square); its bar is checked signed in.
      '/improvements/contribute',
    ]) {
      testWidgets('when 360 px wide on $path then the actions are one menu '
          'and the bar does not overflow', (tester) async {
        current = await pumpBoard(
          tester,
          path,
          board: seeded(),
          size: const Size(360, 800),
          signedIn: false,
        );

        expect(tester.takeException(), isNull);
        expect(byKey('board.actions.more'), findsOneWidget);
        expect(byKey('board.signIn'), findsOneWidget);
        await tap(tester, 'board.actions.more');
        expect(byKey('board.reportBug'), findsOneWidget);
        expect(byKey('board.suggest'), findsOneWidget);
        await settleTooltips(tester);
      });
    }

    testWidgets('when 360 px wide on a task signed in then the bar does not '
        'overflow', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/t/1?list=tasks',
        board: seeded(),
        size: const Size(360, 800),
      );

      expect(tester.takeException(), isNull);
      expect(byKey('board.actions.more'), findsOneWidget);
      expect(byKey('board.crumb.more'), findsOneWidget);
      await settleTooltips(tester);
    });
  });

  group('Given the tabs bar', () {
    testWidgets('then each tab has its count as a badge (none on Done), the '
        'active tab is selected, and the admin sees Review with its badge', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final b = seeded(admin: true);
      current = await pumpBoard(tester, '/improvements/bugs', board: b);

      String count(String tab) => (tester.widget<Text>(
        find.descendant(
          of: byKey('board.tab.$tab.count'),
          matching: find.byType(Text),
        ),
      )).data!;
      expect(count('improvements'), '2');
      expect(count('bugs'), '1');
      expect(count('tasks'), '1');
      expect(count('claimed'), '0');
      expect(byKey('board.tab.done.count'), findsNothing);
      expect(byKey('board.tab.review.count'), findsOneWidget);

      final bugs = tester.getSemantics(byKey('board.tab.bugs'));
      expect(bugs.getSemanticsData().role, SemanticsRole.tab);
      expect(bugs.flagsCollection.isSelected, Tristate.isTrue);
      expect(bugs.label, 'Bugs, 1');
      await settleTooltips(tester);
      semantics.dispose();
    });

    for (final br in Brightness.values) {
      testWidgets('in ${br.name} then the count badges are small and bold '
          'with readable contrast, active or not', (tester) async {
        current = await pumpBoard(
          tester,
          '/improvements/bugs',
          board: seeded(),
          brightness: br,
        );
        final background = ShadTheme.of(
          tester.element(byKey('board.tabs')),
        ).colorScheme.background;
        double contrast(Color a, Color b) {
          final la = a.computeLuminance(), lb = b.computeLuminance();
          return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
        }

        for (final tab in ['bugs', 'improvements']) {
          final badge = byKey('board.tab.$tab.count');
          final style = tester
              .widget<Text>(
                find.descendant(of: badge, matching: find.byType(Text)),
              )
              .style!;
          expect(style.fontSize, 11, reason: tab);
          expect(style.fontWeight, FontWeight.w600, reason: tab);
          final fill =
              (tester
                          .widget<Container>(
                            find.descendant(
                              of: badge,
                              matching: find.byType(Container),
                            ),
                          )
                          .decoration!
                      as BoxDecoration)
                  .color!;
          final behind = Color.alphaBlend(fill, background);
          expect(
            contrast(Color.alphaBlend(style.color!, behind), behind),
            greaterThanOrEqualTo(4.5),
            reason: '$tab in ${br.name}',
          );
        }
        await settleTooltips(tester);
      });
    }

    testWidgets('when a tab is focused with the keyboard then Enter opens it', (
      tester,
    ) async {
      current = await pumpBoard(tester, '/improvements', board: seeded());

      bool bugsFocused() {
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) return false;
        var found = false;
        ctx.visitAncestorElements((e) {
          found = e.widget.key == const ValueKey<String>('board.tab.bugs');
          return !found;
        });
        return found;
      }

      for (var i = 0; i < 20 && !bugsFocused(); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(bugsFocused(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(t().location, '/improvements/bugs');
      await settleTooltips(tester);
    });

    testWidgets('when tabs are switched then the history entry is replaced '
        'and the breadcrumb follows', (tester) async {
      current = await pumpBoard(tester, '/recent', board: seeded());
      recordHistory();
      await t().go(tester, '/improvements');
      final depth = t().s.navHistory.length;

      await tap(tester, 'board.tab.bugs');
      await tap(tester, 'board.tab.done');

      expect(t().location, '/improvements/done');
      expect(crumbText('list'), 'Done');
      expect(t().s.navHistory.length, depth);
      expect(t().s.navHistory[depth - 2], '/recent');
      await settleTooltips(tester);
    });
  });

  test('boardBackTarget is the last route outside the board', () async {
    final h = CommandTestHarness();
    addTearDown(h.dispose);
    for (final l in ['/recent', '/improvements', '/improvements/p/1']) {
      h.services.recordLocation(l);
    }
    expect(boardBackTarget(h.services), '/recent');
  });
}
