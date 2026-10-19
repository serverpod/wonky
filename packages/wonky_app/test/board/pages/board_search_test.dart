import 'dart:ui' show Tristate;

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/testing.dart';

import 'support/board_pump.dart';

/// The board's search (specs/16 §4.4): the search button and its popover
/// (field, *Kind*, *Include closed*), the results across all
/// posts, the search chip, the URL; and the *Up for grabs* / *Claimed*
/// tabs with their counts and live moves.
void main() {
  BoardTest? current;
  BoardTest t() => current!;
  tearDown(() async {
    await current?.dispose();
    current = null;
  });

  /// #1–#3 open ideas, #4 an open bug, #5 a shipped idea, #6 a declined bug.
  FakeBoardRepository seeded() => FakeBoardRepository()
    ..seedPost(title: 'Dark mode for slides', score: 5)
    ..seedPost(title: 'Comment threads in Sheets', score: 9)
    ..seedPost(title: 'Sorting by name in Drive', score: 2)
    ..seedPost(title: 'Paste loses styles', kind: BoardPostKind.bug, score: 4)
    ..seedPost(
      title: 'Shipped dark charts',
      status: BoardPostStatus.shipped,
      score: 30,
    )
    ..seedPost(
      title: 'Declined dark bug',
      kind: BoardPostKind.bug,
      status: BoardPostStatus.declined,
    );

  Finder row(int n) => byKey('board.row.$n');

  bool tabSelected(WidgetTester tester, String tab) =>
      tester.getSemantics(byKey('board.tab.$tab')).flagsCollection.isSelected ==
      Tristate.isTrue;

  String? tabCount(String tab) =>
      (find
                  .descendant(
                    of: byKey('board.tab.$tab.count'),
                    matching: find.byType(Text),
                  )
                  .evaluate()
                  .single
                  .widget
              as Text)
          .data;

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(byKey(key));
    await tester.pumpAndSettle();
  }

  /// Opens the popover, types [text] and runs the search with Enter.
  Future<void> searchFor(WidgetTester tester, String text) async {
    await tap(tester, 'board.search');
    await tester.enterText(byKey('board.search.input'), text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  group('Given the search button', () {
    testWidgets('when searching all posts then the results view lists '
        'matches across lists, no tab is selected, the button is highlighted '
        'and the URL holds the search', (tester) async {
      current = await pumpBoard(tester, '/improvements', board: seeded());
      final semantics = tester.ensureSemantics();

      await searchFor(tester, 'dar');

      expect(t().location, '/improvements/search?q=dar');
      expect(
        find.descendant(
          of: byKey('board.search.header'),
          matching: find.text('Results for “dar”'),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      expect(row(1), findsOneWidget, reason: 'prefix of "Dark"');
      expect(row(2), findsNothing);
      expect(row(5), findsNothing, reason: 'closed posts are excluded');
      expect(row(6), findsNothing);
      for (final tab in ['improvements', 'bugs', 'tasks', 'claimed']) {
        expect(tabSelected(tester, tab), isFalse, reason: tab);
      }
      expect(
        tester.getSemantics(byKey('board.search')).flagsCollection.isToggled,
        Tristate.isTrue,
      );
      expect(byKey('board.filter.search'), findsOneWidget);
      expect(find.text('Search: “dar”'), findsOneWidget);
      semantics.dispose();
      await settleTooltips(tester);
    });

    testWidgets('when searching for part of a title then the substring '
        'matches, and a bug shows next to ideas', (tester) async {
      current = await pumpBoard(tester, '/improvements', board: seeded());

      await searchFor(tester, 'ste');

      expect(row(4), findsOneWidget, reason: 'Pa*ste* loses styles (bug)');
      expect(row(1), findsNothing);
      await settleTooltips(tester);
    });

    testWidgets('when searching for #3 then that post is listed', (
      tester,
    ) async {
      current = await pumpBoard(tester, '/improvements', board: seeded());

      await searchFor(tester, '#3');

      expect(row(3), findsOneWidget);
      await settleTooltips(tester);
    });

    testWidgets('when Include closed and a kind are chosen then closed posts '
        'of that kind are found and the URL keeps the options', (tester) async {
      current = await pumpBoard(tester, '/improvements', board: seeded());

      await tap(tester, 'board.search');
      await tester.enterText(byKey('board.search.input'), 'dark');
      await tap(tester, 'board.search.closed');
      await tap(tester, 'board.search.kind.idea');
      await tap(tester, 'board.search.submit');

      expect(t().location, '/improvements/search?q=dark&closed=1&kind=idea');
      expect(row(1), findsOneWidget);
      expect(row(5), findsOneWidget, reason: 'shipped, with Include closed');
      expect(row(6), findsNothing, reason: 'a bug');
      await settleTooltips(tester);
    });

    testWidgets('when the popover opens on a tab then it offers only Kind '
        '(All, Bugs, Improvements) and Include closed, and the search covers '
        'all posts in the results view', (tester) async {
      current = await pumpBoard(tester, '/improvements/bugs', board: seeded());
      final semantics = tester.ensureSemantics();

      await tap(tester, 'board.search');
      Finder inPanel(String text) => find.descendant(
        of: byKey('board.search.panel'),
        matching: find.text(text),
      );
      expect(byKey('board.search.in'), findsNothing);
      expect(inPanel('Search in'), findsNothing);
      expect(inPanel('Kind'), findsOneWidget);
      for (final (key, label) in [
        ('any', 'All'),
        ('bug', 'Bugs'),
        ('idea', 'Improvements'),
      ]) {
        expect(
          find.descendant(
            of: byKey('board.search.kind.$key'),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      expect(byKey('board.search.closed'), findsOneWidget);

      await tester.enterText(byKey('board.search.input'), 'dark');
      await tap(tester, 'board.search.closed');
      await tap(tester, 'board.search.submit');

      expect(t().location, '/improvements/search?q=dark&closed=1');
      expect(tabSelected(tester, 'bugs'), isFalse);
      expect(row(1), findsOneWidget, reason: 'an idea is found from Bugs');
      expect(row(5), findsOneWidget);
      expect(row(6), findsOneWidget);

      await tap(tester, 'board.filter.search');

      expect(t().location, '/improvements');
      semantics.dispose();
      await settleTooltips(tester);
    });

    testWidgets('when a tab URL carries an old search then the tab shows '
        'unfiltered', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/bugs?q=dark&closed=1',
        board: seeded(),
      );

      expect(byKey('board.filter.search'), findsNothing);
      expect(row(4), findsOneWidget);
      expect(row(6), findsNothing);
      await settleTooltips(tester);
    });

    testWidgets('when the URL holds a search then a reload shows it, a post '
        'opens under the results and the crumb returns to them', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/search?q=comment&kind=idea',
        board: seeded(),
        size: const Size(2400, 1000),
      );

      expect(row(2), findsOneWidget);
      await tap(tester, 'board.row.2');
      expect(t().location, '/improvements/p/2?list=search&q=comment&kind=idea');
      expect(
        find.descendant(
          of: byKey('board.crumb.list'),
          matching: find.text('Results for “comment”'),
          matchRoot: true,
        ),
        findsOneWidget,
      );

      await tap(tester, 'board.crumb.list');

      expect(t().location, '/improvements/search?q=comment&kind=idea');
      expect(row(2), findsOneWidget);
      await settleTooltips(tester);
    });

    testWidgets('when Clear is pressed in the popover then the search ends', (
      tester,
    ) async {
      current = await pumpBoard(
        tester,
        '/improvements/search?q=dark',
        board: seeded(),
      );

      await tap(tester, 'board.search');
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: byKey('board.search.input'),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'dark',
      );
      await tap(tester, 'board.search.clear');

      expect(t().location, '/improvements');
      expect(byKey('board.search.panel'), findsNothing);
      expect(byKey('board.filter.search'), findsNothing);
      await settleTooltips(tester);
    });

    testWidgets('when / is pressed then the popover opens with the field '
        'focused, and Esc closes it', (tester) async {
      current = await pumpBoard(tester, '/improvements', board: seeded());

      await tester.sendKeyEvent(LogicalKeyboardKey.slash, character: '/');
      await tester.pumpAndSettle();

      expect(byKey('board.search.panel'), findsOneWidget);
      final field = tester.widget<EditableText>(
        find.descendant(
          of: byKey('board.search.input'),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.focusNode.hasFocus, isTrue);
      expect(field.controller.text, isEmpty, reason: 'the / is not typed');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(byKey('board.search.panel'), findsNothing);
      await settleTooltips(tester);
    });

    testWidgets('when nothing matches then the empty state suggests '
        'broadening the search', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/search?q=zzz',
        board: seeded(),
      );

      expect(find.text('No issues match your search'), findsOneWidget);
      expect(
        find.text(
          'Try fewer words or part of a word, or include closed issues.',
        ),
        findsOneWidget,
      );
      await settleTooltips(tester);
    });
  });

  group('Given published, claimed and in-review tasks', () {
    FakeBoardRepository withTasks() {
      final b = seeded();
      b.seedTask(title: 'Open task');
      b.seedTask(title: 'Claimed task', claimedById: 2);
      b.seedTask(title: 'Reviewed task', status: BoardTaskStatus.inReview);
      return b;
    }

    testWidgets('when the board opens then Up for grabs and Claimed have '
        'their own counts from the server', (tester) async {
      current = await pumpBoard(tester, '/improvements', board: withTasks());

      expect(tabCount('tasks'), '1');
      expect(tabCount('claimed'), '2');
      expect(t().board.calls, contains('counts'));
      await settleTooltips(tester);
    });

    testWidgets('when Up for grabs is open then it lists only unclaimed '
        'tasks; Claimed lists the claimed and in-review ones', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/tasks',
        board: withTasks(),
      );

      expect(byKey('board.task.1'), findsOneWidget);
      expect(byKey('board.task.2'), findsNothing);
      expect(byKey('board.task.3'), findsNothing);

      await tap(tester, 'board.tab.claimed');

      expect(t().location, '/improvements/claimed');
      expect(byKey('board.task.1'), findsNothing);
      expect(byKey('board.task.2'), findsOneWidget);
      expect(byKey('board.task.3'), findsOneWidget);
      await settleTooltips(tester);
    });

    testWidgets('when a task is claimed elsewhere then it moves from Up for '
        'grabs to Claimed live, with the counts', (tester) async {
      final b = withTasks();
      current = await pumpBoard(tester, '/improvements/tasks', board: b);
      expect(byKey('board.task.1'), findsOneWidget);

      b.tasks[1]!
        ..status = BoardTaskStatus.claimed
        ..claimedById = 2
        ..claimExpiresAt = clock.now().add(const Duration(hours: 30));
      b.emitTask(1);
      await tester.pumpAndSettle();

      expect(byKey('board.task.1'), findsNothing);
      expect(byKey('board.tasks.empty'), findsOneWidget);
      expect(tabCount('tasks'), '0');
      expect(tabCount('claimed'), '3');
      await settleTooltips(tester);
    });

    testWidgets('when a claimed task opens from Claimed then the trail is '
        'root › Claimed › T-2', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/claimed',
        board: withTasks(),
      );

      await tap(tester, 'board.task.2');

      expect(t().location, '/improvements/t/2?list=claimed');
      await settleTooltips(tester);
    });

    testWidgets('when a claimed task opens from a bare link then its list '
        'crumb is Claimed', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/t/3',
        board: withTasks(),
        size: const Size(2400, 1000),
      );

      expect(
        find.descendant(
          of: byKey('board.crumb.list'),
          matching: find.text('Claimed'),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      await settleTooltips(tester);
    });

    testWidgets('when no task is claimed then Claimed shows its empty '
        'state', (tester) async {
      current = await pumpBoard(
        tester,
        '/improvements/claimed',
        board: seeded()..seedTask(),
      );

      expect(find.text('No claimed tasks'), findsOneWidget);
      await settleTooltips(tester);
    });
  });
}
