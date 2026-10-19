import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/screen_pump.dart';
import 'support/board_pump.dart';

/// The post page (specs/16 §4.5): moderation states per viewer, details,
/// relations, comments through `CommentThreadBody.custom`, the ⋮ menu
/// (author, signed in, admin) and the flag dialog.
void main() {
  BoardTest? current;
  BoardTest t() => current!;
  tearDown(() async {
    await current?.dispose();
    current = null;
  });

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(byKey('board.post.menu'));
    await tester.pumpAndSettle();
  }

  testWidgets('Given a visible post then its title, Markdown body, labels, '
      'details and comments show', (tester) async {
    final b = FakeBoardRepository();
    final p = b.seedPost(
      title: 'Paste into merged cells drops styles',
      body: '## What happened\nIt loses the **bold**.',
      kind: BoardPostKind.bug,
      aiLabels: true,
      contextJson: '{"app":"Sheets 2.3.1","route":"/s/:id"}',
    );
    b.seedComment(postNumber: p.number, body: 'Same *here*');
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    expect(find.text('Paste into merged cells drops styles'), findsOneWidget);
    expect(find.text('What happened'), findsOneWidget);
    expect(find.text('AI'), findsNWidgets(2), reason: 'area and size');
    expect(
      byKey('board.comment.${b.comments.keys.single}.body'),
      findsOneWidget,
    );
    expect(byKey('board.post.admin'), findsNothing);

    await tester.tap(byKey('board.post.details'));
    await tester.pumpAndSettle();
    expect(find.text('Sheets 2.3.1'), findsOneWidget);
    expect(find.text('/s/:id'), findsOneWidget);
    await settleTooltips(tester);
  });

  for (final kind in BoardPostKind.values) {
    testWidgets('Given a ${kind.name} post then #n, the title and ⋮ share one '
        'top-aligned line, the chips sit below, and the vote control is ▲ n ▼ '
        'at the start', (tester) async {
      final b = FakeBoardRepository();
      b.seedPost(
        title: 'A rather long title that wraps onto a second line on the page',
        kind: kind,
        score: 3,
      );
      current = await pumpBoard(tester, '/improvements/p/1', board: b);
      final semantics = tester.ensureSemantics();

      final header = byKey('board.post.header');
      for (final k in ['board.post.number', 'board.post.title']) {
        expect(
          find.descendant(of: header, matching: byKey(k)),
          findsOneWidget,
          reason: k,
        );
      }
      expect(
        find.descendant(of: header, matching: byKey('board.post.menu')),
        findsOneWidget,
      );
      final number = tester.getRect(byKey('board.post.number'));
      final title = tester.getRect(byKey('board.post.title'));
      final menu = tester.getRect(byKey('board.post.menu'));
      expect(title.top, number.top, reason: 'top-aligned');
      expect(menu.top, lessThanOrEqualTo(title.top));
      expect(number.right, lessThan(title.left));
      expect(title.right, lessThanOrEqualTo(menu.left));
      expect(
        tester
            .getTopLeft(
              find.text(kind == BoardPostKind.bug ? 'Bug' : 'Improvement'),
            )
            .dy,
        greaterThan(title.bottom - 1),
        reason: 'the chips are below the title line',
      );

      // The same vote control for both kinds, before the header.
      expect(byKey('board.vote.1.hit'), findsNothing);
      expect(find.text('I hit this too'), findsNothing);
      expect(byKey('board.vote.1.up'), findsOneWidget);
      expect(tester.widget<Text>(byKey('board.vote.1.score')).data, '3');
      expect(
        tester.getTopLeft(byKey('board.vote.1.up')).dx,
        lessThan(number.left),
      );
      final down = tester.getSemantics(byKey('board.vote.1.down'));
      expect(
        down.flagsCollection.isEnabled == Tristate.isTrue,
        kind == BoardPostKind.idea,
        reason: 'bugs can only be upvoted',
      );
      semantics.dispose();
      await settleTooltips(tester);
    });
  }

  testWidgets('Given a bug when its up arrow is pressed then it is voted '
      'through shell.board.vote', (tester) async {
    final b = FakeBoardRepository();
    b.seedPost(title: 'Paste drops styles', kind: BoardPostKind.bug);
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    await tester.tap(byKey('board.vote.1.up'));
    await tester.pumpAndSettle();

    expect(b.posts[1]!.votes[1], 1);
    expect(t().h.undoLabels, isNotEmpty);
    await settleTooltips(tester);
  });

  testWidgets('Given a signed-in user when replying then the comment is '
      'posted through shell.board.comment.add and is undoable', (tester) async {
    final b = FakeBoardRepository()..seedPost();
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    await tester.tap(byKey('board.reply.post-1.open'));
    await tester.pumpAndSettle();
    await enterMarkdown(tester, byKey('board.reply.post-1'), 'I want this too');
    await tester.tap(byKey('board.reply.post-1.send'));
    await tester.pumpAndSettle();

    final c = b.comments.values.single;
    expect((c.body, c.authorId), ('I want this too', 1));
    expect(find.text('I want this too'), findsOneWidget);

    await t().h.undo();
    await tester.pumpAndSettle();
    expect(c.deleted, isTrue);
    await settleTooltips(tester);
  });

  testWidgets('Given a signed-out visitor then comments are read-only with '
      'Sign in to comment', (tester) async {
    final b = FakeBoardRepository()..seedPost();
    b.seedComment(postNumber: 1);
    current = await pumpBoard(
      tester,
      '/improvements/p/1',
      board: b,
      signedIn: false,
    );

    expect(byKey('board.post.signInToComment'), findsOneWidget);
    expect(byKey('board.reply.post-1.open'), findsNothing);
    await settleTooltips(tester);
  });

  testWidgets('Given my post still checking then I see Checking your issue', (
    tester,
  ) async {
    final b = FakeBoardRepository()
      ..seedPost(authorId: 1, moderation: BoardModeration.checking);
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    expect(byKey('board.post.notice.checking'), findsOneWidget);
    expect(find.text('Checking your issue…'), findsOneWidget);
  });

  testWidgets('Given my held post then I see Waiting for review; others '
      "can't see it", (tester) async {
    final b = FakeBoardRepository()
      ..seedPost(authorId: 1, moderation: BoardModeration.held);
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    expect(
      find.text('Waiting for review: a moderator will look at it.'),
      findsOneWidget,
    );

    b.userId = 2;
    await t().go(tester, '/improvements');
    await t().go(tester, '/improvements/p/1');
    expect(byKey('board.post.notFound'), findsOneWidget);
    await settleTooltips(tester);
  });

  testWidgets('Given my removed post then the moderator\'s reason shows and '
      'commenting is closed', (tester) async {
    final b = FakeBoardRepository()
      ..seedPost(
        authorId: 1,
        moderation: BoardModeration.removed,
        moderationReason: 'Spam',
      );
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    expect(find.text('Removed by a moderator. Spam'), findsOneWidget);
    expect(byKey('board.reply.post-1.open'), findsNothing);
  });

  testWidgets('Given my post when I delete it from the menu then it shows as '
      'deleted and undo restores it', (tester) async {
    final b = FakeBoardRepository()..seedPost(authorId: 1);
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    await openMenu(tester);
    expect(byKey('board.post.menu.edit'), findsOneWidget);
    await tester.tap(byKey('board.post.menu.delete'));
    await tester.pumpAndSettle();

    expect(byKey('board.post.notice.deleted'), findsOneWidget);
    await t().h.undo();
    await tester.pumpAndSettle();
    expect(byKey('board.post.notice.deleted'), findsNothing);
    await settleTooltips(tester);
  });

  testWidgets("Given someone else's post when flagging it then the dialog "
      'asks for a reason and the flag is sent', (tester) async {
    final b = FakeBoardRepository()..seedPost();
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    await openMenu(tester);
    expect(byKey('board.post.menu.edit'), findsNothing);
    expect(byKey('board.post.menu.labels'), findsNothing);
    await tester.tap(byKey('board.post.menu.flag'));
    await tester.pumpAndSettle();
    expect(byKey('dialog.board.flag'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: byKey('dialog.board.flag.note'),
        matching: find.byType(EditableText),
      ),
      'Advertising',
    );
    await tester.tap(byKey('dialog.board.flag.flag'));
    await tester.pumpAndSettle();

    expect(b.flags['post:1']![1], (BoardFlagReason.spam, 'Advertising'));
    await settleTooltips(tester);
  });

  testWidgets('Given an admin then the menu has the moderation actions and '
      'the moderation panel shows scores, flags and hints', (tester) async {
    final b = FakeBoardRepository(isAdmin: true);
    b.seedPost(title: 'Target post');
    b.seedPost(
      possibleDuplicateOf: 1,
      suggestedTitle: 'A clearer title',
      triageJson: '{"spam":0.62,"offensive":0.01}',
      needsCheck: true,
    );
    await b.flag(number: 2, reason: BoardFlagReason.spam);
    current = await pumpBoard(tester, '/improvements/p/2', board: b);

    expect(byKey('board.post.admin'), findsOneWidget);
    expect(find.textContaining('spam 0.62'), findsOneWidget);
    expect(byKey('board.post.flags'), findsOneWidget);
    expect(find.text('Possible duplicate of #1'), findsOneWidget);
    await openMenu(tester);
    for (final k in [
      'labels',
      'applyTitle',
      'hold',
      'remove',
      'decline',
      'merge',
      'select',
      'block',
    ]) {
      expect(byKey('board.post.menu.$k'), findsOneWidget, reason: k);
    }
    await tester.tap(byKey('board.post.menu.hold'));
    await tester.pumpAndSettle();
    expect(b.posts[2]!.moderation, BoardModeration.held);

    await tester.tap(byKey('board.post.mergeHint'));
    await tester.pumpAndSettle();
    expect(b.posts[2]!.duplicateOf, 1);
    await settleTooltips(tester);
  });

  testWidgets('Given a merged duplicate when a non-admin opens it then the '
      'target opens with a note', (tester) async {
    final b = FakeBoardRepository();
    b.seedPost(title: 'Target post');
    b.seedPost(title: 'Duplicate');
    b.posts[2]!
      ..status = BoardPostStatus.duplicate
      ..duplicateOf = 1;
    current = await pumpBoard(tester, '/improvements/p/2', board: b);

    expect(t().location, '/improvements/p/1?merged=2');
    expect(byKey('board.post.notice.merged'), findsOneWidget);
    expect(find.text('Target post'), findsOneWidget);
  });

  testWidgets('Given a planned post then it links to its task', (tester) async {
    final b = FakeBoardRepository()..seedPost();
    b.seedTask(posts: [1], title: 'Merged cells task');
    current = await pumpBoard(tester, '/improvements/p/1', board: b);

    await tester.tap(byKey('board.post.link.task'));
    await tester.pumpAndSettle();

    expect(t().location, '/improvements/t/1');
    await settleTooltips(tester);
  });

  testWidgets('Given a live update when the post changes on the server then '
      'the page reloads', (tester) async {
    final b = FakeBoardRepository()
      ..seedPost(authorId: 1, moderation: BoardModeration.checking);
    current = await pumpBoard(tester, '/improvements/p/1', board: b);
    expect(byKey('board.post.notice.checking'), findsOneWidget);

    b.posts[1]!.moderation = BoardModeration.visible;
    b.emitPost(1);
    await tester.pumpAndSettle();

    expect(byKey('board.post.notice.checking'), findsNothing);
  });

  for (final br in Brightness.values) {
    testWidgets('Given a post in ${br.name} then it is accessible', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final b = FakeBoardRepository()..seedPost(kind: BoardPostKind.bug);
      b.seedComment(postNumber: 1);
      current = await pumpBoard(
        tester,
        '/improvements/p/1',
        board: b,
        brightness: br,
      );

      await expectAccessible(tester);
      semantics.dispose();
      await settleTooltips(tester);
    });
  }
}
