import 'dart:convert';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/src/board/report/board_report_dialog.dart';
import 'package:wonky_app/src/board/report/board_report_services.dart';
import 'package:wonky_app/src/board/report/report_draft.dart';
import 'package:wonky_app/src/board/report/similar_posts.dart';
import 'package:wonky_app/src/board/screenshot/screenshot_annotations.dart';
import 'package:wonky_app/src/board/screenshot/screenshot_editor.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import 'support/report_fakes.dart';

/// The report dialog of Bugs & improvements (specs/16 §4.2) through
/// `shell.board.report` and its aliases.
void main() {
  late CommandTestHarness h;
  late FakeReportBoard board;

  String field(BoardReportField f) => BoardReportKeys.field(f);

  setUp(() {
    board = FakeReportBoard();
    h = reportHarness(board: board);
  });
  tearDown(() => h.dispose());

  BoardReportDialogState dialog(WidgetTester tester) =>
      tester.state<BoardReportDialogState>(find.byType(BoardReportDialog));

  Future<void> openReport(
    WidgetTester tester, {
    String id = 'shell.board.report',
    Map<String, Object?> args = const {},
    Size size = const Size(1280, 800),
    Brightness brightness = Brightness.light,
  }) async {
    await pumpReportShell(
      tester,
      h,
      InvokeButton(id, args: args),
      size: size,
      brightness: brightness,
    );
    await tester.tap(key('test.invoke'));
    await tester.pumpAndSettle();
  }

  /// Lets toasts and tooltips time out.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  }

  group('Given shell.board.report', () {
    testWidgets('when invoked then the app is captured before the dialog '
        'opens and the capture can be added', (tester) async {
      final image = await solidImage(tester, 320, 200);
      bool? dialogShownAtCapture;
      BoardReportServices.of(h.services).capture = () async {
        dialogShownAtCapture = key(
          BoardReportKeys.dialog,
        ).evaluate().isNotEmpty;
        return image;
      };

      await openReport(tester);

      expect(dialogShownAtCapture, isFalse);
      expect(key(BoardReportKeys.dialog), findsOneWidget);
      expect(key(BoardReportKeys.addScreenshot), findsOneWidget);
      expect(key(BoardReportKeys.screenshotWarning), findsOneWidget);
      expect(key(BoardReportKeys.captureFailed), findsNothing);
    });

    testWidgets('when the capture fails then "Couldn\'t capture the screen" '
        'shows and there is no Add screenshot', (tester) async {
      await openReport(tester);

      expect(key(BoardReportKeys.captureFailed), findsOneWidget);
      expect(find.text('Couldn’t capture the screen'), findsOneWidget);
      expect(key(BoardReportKeys.addScreenshot), findsNothing);
    });

    testWidgets('when signed out then the board page opens instead', (
      tester,
    ) async {
      await h.dispose();
      h = reportHarness(
        board: board,
        auth: FakeAuthRepository(signedIn: false),
      );
      var captured = false;
      BoardReportServices.of(h.services).capture = () async {
        captured = true;
        return null;
      };

      final r = await h.invoke('shell.board.report');

      expect(r.isOk, isTrue);
      expect(routerPath(h), '/improvements');
      expect(captured, isFalse);
    });

    testWidgets('when the server has the board off then the GitHub link '
        'is offered', (tester) async {
      await h.dispose();
      h = reportHarness(
        board: board,
        urls: AppUrls.fromJson(const {'board': false}),
      );

      await openReport(tester);

      expect(key('dialog.externalLink'), findsOneWidget);
      expect(find.textContaining('github.com'), findsOneWidget);
      expect(key(BoardReportKeys.dialog), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        h.services.dispatcher.stateOf('shell.board.open').enabled,
        isFalse,
      );
    });

    test('when config.json has no board flag then the board is on', () {
      expect(AppUrls.fromJson(const {}).board, isTrue);
      expect(AppUrls.fromJson(const {'board': true}).board, isTrue);
      expect(AppUrls.fromJson(const {'board': false}).board, isFalse);
    });
  });

  group('Given shell.board.open', () {
    test('when invoked then the board page shows, a tab below it', () async {
      await h.invoke('shell.board.open');
      expect(routerPath(h), '/improvements');
      await h.invoke('shell.board.open', {'tab': 'bugs'});
      expect(routerPath(h), '/improvements/bugs');
      await h.invoke('shell.board.open', {'tab': 'improvements'});
      expect(routerPath(h), '/improvements');
      expect(h.crossApp.opened, isEmpty);
      expect(h.crossApp.external, isEmpty);
    });
  });

  group('Given the old ids', () {
    testWidgets('when shell.help.reportBug runs then the dialog opens on '
        'Bug', (tester) async {
      await BoardReportDraftStore(
        h.services.userStore,
        WonkyAppKind.write,
      ).save(
        const BoardReportDraft(
          kind: BoardPostKind.idea,
          text: {BoardReportField.idea: 'Dark mode for charts'},
        ),
      );

      await openReport(tester, id: 'shell.help.reportBug');

      expect(dialog(tester).draft.kind, BoardPostKind.bug);
      expect(find.text('Post bug'), findsOneWidget);
    });

    testWidgets('when shell.help.feedback runs then the dialog opens on the '
        'draft\'s kind', (tester) async {
      await BoardReportDraftStore(
        h.services.userStore,
        WonkyAppKind.write,
      ).save(
        const BoardReportDraft(
          kind: BoardPostKind.idea,
          text: {BoardReportField.idea: 'Dark mode for charts'},
        ),
      );

      await openReport(tester, id: 'shell.help.feedback');

      expect(dialog(tester).draft.kind, BoardPostKind.idea);
      expect(find.text('Post improvement'), findsOneWidget);
      // The composer draws its text as rich text (WYSIWYG, 16 §7.3).
      expect(
        find.text('Dark mode for charts', findRichText: true),
        findsOneWidget,
      );
    });

    test('then both stay registered but leave the palette', () {
      for (final id in ['shell.help.reportBug', 'shell.help.feedback']) {
        final c = h.services.registry.byId(id);
        expect(c, isNotNull, reason: id);
        expect(c!.showInPalette, isFalse, reason: id);
      }
      expect(
        h.services.registry.byId('shell.board.report')!.showInPalette,
        isTrue,
      );
    });
  });

  group('Given the report dialog', () {
    testWidgets('when posting an empty bug then the title and "What '
        'happened?" are required', (tester) async {
      await openReport(tester);

      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      expect(
        key(BoardReportKeys.fieldError(BoardReportField.title)),
        findsOneWidget,
      );
      expect(find.text('Use 8 to 120 characters.'), findsOneWidget);
      expect(
        key(BoardReportKeys.fieldError(BoardReportField.happened)),
        findsOneWidget,
      );
      expect(
        key(BoardReportKeys.fieldError(BoardReportField.expected)),
        findsNothing,
      );
      expect(board.posted, isEmpty);

      await enterField(tester, field(BoardReportField.title), 'Too short');
      await enterField(tester, field(BoardReportField.happened), 'It broke');
      await tester.pumpAndSettle();
      expect(
        key(BoardReportKeys.fieldError(BoardReportField.title)),
        findsNothing,
      );
      expect(
        key(BoardReportKeys.fieldError(BoardReportField.happened)),
        findsNothing,
      );
      await settle(tester);
    });

    testWidgets('when posting a bug then the body has the bug sections, '
        'empty ones omitted, and the details are attached', (tester) async {
      h.services.router.go('/d/0190a0e0-0000-7000-8000-000000000001?tab=2');
      await openReport(tester);

      await enterField(
        tester,
        field(BoardReportField.title),
        'Paste into merged cells loses formatting',
      );
      await enterField(tester, field(BoardReportField.happened), 'Bold lost');
      await enterField(
        tester,
        field(BoardReportField.steps),
        '1. Merge\n2. Paste',
      );
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      final d = board.posted.single;
      expect(d.kind, BoardPostKind.bug);
      expect(d.title, 'Paste into merged cells loses formatting');
      expect(
        d.body,
        '## What happened\n\nBold lost\n\n'
        '## Steps to reproduce\n\n1. Merge\n2. Paste',
      );
      expect(d.appHint, 'write');
      expect(d.screenshotFileUuid, isNull);
      final details = jsonDecode(d.contextJson!) as Map;
      expect(details['route'], '/d/:id');
      expect(details['app'], 'write');
      expect(details['browser'], 'Chrome 131');
      expect(details['theme'], 'light');
      expect(details['window'], '1280×800');
      expect(details.containsKey('error'), isFalse);
      expect(key(BoardReportKeys.dialog), findsNothing);
      await settle(tester);
    });

    testWidgets('when posting then it runs shell.board.createPost: one undo '
        'step whose undo deletes the post and redo restores it', (
      tester,
    ) async {
      final invoked = <String>[];
      final sub = h.services.dispatcher.events.listen(
        (e) => invoked.add(e.id.value),
      );
      addTearDown(sub.cancel);
      await openReport(tester, args: const {'kind': 'idea'});
      await enterField(
        tester,
        field(BoardReportField.title),
        'Dark mode for charts please',
      );
      await enterField(tester, field(BoardReportField.idea), 'A dark palette');

      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      expect(invoked, contains('shell.board.createPost'));
      expect(board.posted.single.title, 'Dark mode for charts please');
      expect(h.undoLabels, hasLength(1));
      await h.undo();
      expect(board.log, contains('deletePost 412'));
      await h.redo();
      expect(board.log, contains('restorePost 412'));
      await settle(tester);
    });

    testWidgets('when posting an improvement then the body has Idea and Why '
        'and no details', (tester) async {
      await openReport(tester, args: const {'kind': 'idea'});

      expect(key(field(BoardReportField.happened)), findsNothing);
      expect(key(BoardReportKeys.details), findsNothing);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Dark mode for charts please',
      );
      await enterField(tester, field(BoardReportField.idea), 'A dark palette');
      await enterField(tester, field(BoardReportField.why), 'Night work');
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      final d = board.posted.single;
      expect(d.kind, BoardPostKind.idea);
      expect(d.body, '## Idea\n\nA dark palette\n\n## Why\n\nNight work');
      expect(d.contextJson, isNull);
      await settle(tester);
    });

    testWidgets('when switching the kind then the text is kept', (
      tester,
    ) async {
      await openReport(tester);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Shared title here',
      );
      await tester.tap(key(BoardReportKeys.kindIdea));
      await tester.pumpAndSettle();

      expect(dialog(tester).draft.kind, BoardPostKind.idea);
      expect(find.text('Shared title here'), findsOneWidget);
      expect(key(field(BoardReportField.idea)), findsOneWidget);
      await settle(tester);
    });

    testWidgets('when posted and the post is being checked then the toast '
        'says so and View opens the post', (tester) async {
      await openReport(tester);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');

      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      expect(find.text('Posted. Checking it now…'), findsOneWidget);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(routerPath(h), '/improvements/p/412');
      await settle(tester);
    });

    testWidgets('when the post is visible at once then the toast says '
        'Posted', (tester) async {
      board.moderation = BoardModeration.visible;
      await openReport(tester);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');

      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      expect(find.text('Posted'), findsOneWidget);
      await settle(tester);
    });

    for (final (code, text) in [
      (
        WonkyErrorCode.limitExceeded,
        'You’ve posted a lot recently. Please try again later.',
      ),
      (WonkyErrorCode.forbidden, 'You can’t post on Bugs & improvements.'),
      (WonkyErrorCode.invalidArgument, 'Couldn’t post: Bad title.'),
    ]) {
      testWidgets('when the server answers ${code.name} then it shows in the '
          'dialog', (tester) async {
        board.postError = WonkyException(code: code, message: 'Bad title.');
        await openReport(tester);
        await enterField(
          tester,
          field(BoardReportField.title),
          'Crash on paste now',
        );
        await enterField(tester, field(BoardReportField.happened), 'Crash');

        await tester.tap(key(BoardReportKeys.post));
        await tester.pumpAndSettle();

        expect(key(BoardReportKeys.dialog), findsOneWidget);
        expect(key(BoardReportKeys.error), findsOneWidget);
        expect(find.text(text), findsOneWidget);
        await settle(tester);
      });
    }

    testWidgets('when the user is blocked then posting is disabled and the '
        'reason shows', (tester) async {
      board.meValue = board.meValue.copyWith(
        blocked: true,
        blockedReason: 'Spam',
      );
      await openReport(tester);

      expect(
        find.text('You can’t post on Bugs & improvements: Spam'),
        findsOneWidget,
      );
      await tester.tap(key(BoardReportKeys.post), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(board.log, isNot(contains('createPost')));
    });

    testWidgets('then the notices name the AI checks and the security '
        'contact', (tester) async {
      await openReport(tester);
      expect(
        find.text(
          'Issues are public and checked automatically by AI (Jev, Gemini).',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Security issue? Don’t post it here: email security@serverpod.dev',
        ),
        findsOneWidget,
      );
    });

    testWidgets('when the board AI is off then only "Issues are public." '
        'shows', (tester) async {
      board.meValue = board.meValue.copyWith(aiChecks: false);
      await openReport(tester);
      expect(find.text('Issues are public.'), findsOneWidget);
      expect(find.textContaining('Jev'), findsNothing);
    });
  });

  group('Given similar posts', () {
    testWidgets('when typing then the search waits 400 ms and needs three '
        'words', (tester) async {
      board.similarPosts = [similarPost(388, 'Merged cells: paste odd')];
      await openReport(tester);

      await enterField(tester, field(BoardReportField.title), 'Paste merged');
      await tester.pump(const Duration(milliseconds: 500));
      expect(board.similarQueries, isEmpty, reason: 'two words');

      await enterField(
        tester,
        field(BoardReportField.title),
        'Paste merged cells',
      );
      await tester.pump(const Duration(milliseconds: 399));
      expect(board.similarQueries, isEmpty, reason: 'debounced');
      await enterField(
        tester,
        field(BoardReportField.title),
        'Paste merged cells x',
      );
      await tester.pump(const Duration(milliseconds: 399));
      expect(board.similarQueries, isEmpty, reason: 'restarted');
      await tester.pump(const Duration(milliseconds: 2));
      expect(board.similarQueries, hasLength(1));
      expect(board.similarQueries.single, startsWith('Paste merged cells x|'));
      expect(board.similarQueries.single, endsWith('|bug'));
      await tester.pumpAndSettle();

      expect(key('${BoardSimilarPostsPanel.keyPrefix}.388'), findsOneWidget);
      expect(find.text('#388 Merged cells: paste odd'), findsOneWidget);
      await settle(tester);
    });

    testWidgets('when voting instead on a bug then it is "I hit this too", '
        'the dialog closes and the draft is kept', (tester) async {
      board.similarPosts = [similarPost(412, 'Paste into merged cells')];
      await openReport(tester);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Paste merged cells fails',
      );
      await tester.pump(const Duration(milliseconds: 401));
      await tester.pumpAndSettle();

      await tester.tap(key('${BoardSimilarPostsPanel.keyPrefix}.412.vote'));
      await tester.pumpAndSettle();

      expect(board.log, contains('vote 412 1'));
      expect(key(BoardReportKeys.dialog), findsNothing);
      expect(find.text('Added “I hit this too” to #412'), findsOneWidget);
      final saved = await BoardReportDraftStore(
        h.services.userStore,
        WonkyAppKind.write,
      ).load();
      expect(saved![BoardReportField.title], 'Paste merged cells fails');
      await settle(tester);
    });

    Future<void> typeTitle(WidgetTester tester) async {
      await enterField(
        tester,
        field(BoardReportField.title),
        'Paste merged cells fails',
      );
      await tester.pump(const Duration(milliseconds: 401));
      await tester.pumpAndSettle();
    }

    testWidgets('when a similar issue is done or shipped then it is not '
        'suggested', (tester) async {
      board.similarPosts = [
        similarPost(412, 'Paste into merged cells'),
        similarPost(413, 'Paste fixed', status: BoardPostStatus.done),
        similarPost(414, 'Paste shipped', status: BoardPostStatus.shipped),
        similarPost(415, 'Paste planned', status: BoardPostStatus.planned),
      ];
      await openReport(tester);
      await typeTitle(tester);

      expect(key('${BoardSimilarPostsPanel.keyPrefix}.412'), findsOneWidget);
      expect(key('${BoardSimilarPostsPanel.keyPrefix}.415'), findsOneWidget);
      expect(key('${BoardSimilarPostsPanel.keyPrefix}.413'), findsNothing);
      expect(key('${BoardSimilarPostsPanel.keyPrefix}.414'), findsNothing);
      await settle(tester);
    });

    for (final b in Brightness.values) {
      testWidgets('when opening a similar issue in ${b.name} then a popup '
          'shows its details and Close returns to the report', (tester) async {
        board.similarPosts = [similarPost(412, 'Paste into merged cells')];
        board.postBodies[412] = 'The **bold** is lost after pasting.';
        await openReport(tester, brightness: b);
        await typeTitle(tester);

        await tester.tap(key('${BoardSimilarPostsPanel.keyPrefix}.412.open'));
        await tester.pumpAndSettle();

        expect(key('dialog.board.similarPost'), findsOneWidget);
        expect(key('dialog.board.similarPost.body'), findsOneWidget);
        expect(find.textContaining('is lost after pasting'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget, reason: 'the status');
        expect(tester.takeException(), isNull);

        await tester.tap(key('dialog.board.similarPost.close'));
        await tester.pumpAndSettle();
        expect(key('dialog.board.similarPost'), findsNothing);
        expect(key(BoardReportKeys.dialog), findsOneWidget);
        expect(board.votes, isEmpty);
        await settle(tester);
      });
    }

    testWidgets('when voting from the popup then it votes instead and both '
        'dialogs close', (tester) async {
      board.similarPosts = [similarPost(412, 'Paste into merged cells')];
      await openReport(tester);
      await typeTitle(tester);

      await tester.tap(key('${BoardSimilarPostsPanel.keyPrefix}.412.open'));
      await tester.pumpAndSettle();
      await tester.tap(key('dialog.board.similarPost.vote'));
      await tester.pumpAndSettle();

      expect(board.log, contains('vote 412 1'));
      expect(key('dialog.board.similarPost'), findsNothing);
      expect(key(BoardReportKeys.dialog), findsNothing);
      await settle(tester);
    });
  });

  group('Given a draft', () {
    testWidgets('when closing with content then "Discard draft?" asks and '
        'Keep draft keeps it for the next time', (tester) async {
      await openReport(tester);
      await enterField(tester, field(BoardReportField.title), 'Half written');

      await tester.tap(key(BoardReportKeys.cancel));
      await tester.pumpAndSettle();
      expect(key('dialog.board.discardDraft'), findsOneWidget);
      await tester.tap(find.text('Keep draft'));
      await tester.pumpAndSettle();
      expect(key(BoardReportKeys.dialog), findsNothing);

      await tester.tap(key('test.invoke'));
      await tester.pumpAndSettle();
      expect(find.text('Half written'), findsOneWidget);
      await settle(tester);
    });

    testWidgets('when discarding then the draft is gone', (tester) async {
      await openReport(tester);
      await enterField(tester, field(BoardReportField.title), 'Half written');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(key(BoardReportKeys.dialog), findsNothing);
      expect(
        await BoardReportDraftStore(
          h.services.userStore,
          WonkyAppKind.write,
        ).load(),
        isNull,
      );
      await settle(tester);
    });

    testWidgets('when the question is dismissed then the dialog stays', (
      tester,
    ) async {
      await openReport(tester);
      await enterField(tester, field(BoardReportField.title), 'Half written');
      await tester.tap(key(BoardReportKeys.cancel));
      await tester.pumpAndSettle();
      expect(key('dialog.board.discardDraft'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(key('dialog.board.discardDraft'), findsNothing);
      expect(key(BoardReportKeys.dialog), findsOneWidget);
      await settle(tester);
    });

    testWidgets('when closing an empty dialog then nothing asks', (
      tester,
    ) async {
      await openReport(tester);
      await tester.tap(key(BoardReportKeys.cancel));
      await tester.pumpAndSettle();
      expect(key('dialog.board.discardDraft'), findsNothing);
      expect(key(BoardReportKeys.dialog), findsNothing);
    });

    testWidgets('when posted then the draft is cleared', (tester) async {
      await openReport(tester);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();
      expect(
        await BoardReportDraftStore(
          h.services.userStore,
          WonkyAppKind.write,
        ).load(),
        isNull,
      );
      await settle(tester);
    });
  });

  group('Given the last error', () {
    void recordError(Duration ago) =>
        BoardReportServices.of(
          h.services,
        ).lastError.value = BoardLastError.from(
          'Bad state: boom\nmore',
          StackTrace.fromString(
            [for (var i = 0; i < 40; i++) '#$i frame$i (package:x/y.dart:$i:1)']
                .join('\n'),
          ),
          at: clock.now().subtract(ago),
        );

    testWidgets('when it happened 2 minutes ago then it is offered, ticked, '
        'and attached', (tester) async {
      recordError(const Duration(minutes: 2, seconds: 5));
      await openReport(tester);

      expect(find.text('Include the last error (2 min ago)'), findsOneWidget);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      final error =
          (jsonDecode(board.posted.single.contextJson!) as Map)['error'] as Map;
      expect(error['message'], 'Bad state: boom\nmore');
      expect(error['stack'], hasLength(30));
      await settle(tester);
    });

    testWidgets('when it is older than 10 minutes then it is not ticked', (
      tester,
    ) async {
      recordError(const Duration(minutes: 25));
      await openReport(tester);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      final details = jsonDecode(board.posted.single.contextJson!) as Map;
      expect(details.containsKey('error'), isFalse);
      await settle(tester);
    });

    testWidgets('when the user unticks it then it is not attached', (
      tester,
    ) async {
      recordError(const Duration(minutes: 1));
      await openReport(tester);
      await tester.ensureVisible(key(BoardReportKeys.includeError));
      await tester.pumpAndSettle();
      await tester.tap(key(BoardReportKeys.includeError));
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      final details = jsonDecode(board.posted.single.contextJson!) as Map;
      expect(details.containsKey('error'), isFalse);
      await settle(tester);
    });

    test('then the message is cut at 4,000 characters', () {
      final e = BoardLastError.from('x' * 5000, null, at: DateTime(2026));
      expect(e.message.length, 4000);
      expect(e.frames, isEmpty);
    });
  });

  group('Given the included details', () {
    testWidgets('when expanded then every detail is listed', (tester) async {
      h.services.router.go('/d/0190a0e0-0000-7000-8000-000000000001');
      await openReport(tester);

      expect(
        find.textContaining('Details that will be included:'),
        findsOneWidget,
      );
      expect(find.textContaining('/d/:id'), findsOneWidget);
      await tester.ensureVisible(key(BoardReportKeys.details));
      await tester.pumpAndSettle();
      await tester.tap(key(BoardReportKeys.details));
      await tester.pumpAndSettle();
      expect(key(BoardReportKeys.detailsList), findsOneWidget);
      expect(find.text('Page: /d/:id'), findsOneWidget);
      expect(
        find.text('Platform: ${BugReportLink.currentPlatform} · Chrome 131'),
        findsOneWidget,
      );
    });
  });

  group('Given a screenshot', () {
    late ui.Image image;

    Future<void> openWithCapture(WidgetTester tester) async {
      image = await solidImage(tester, 400, 200);
      final rs = BoardReportServices.of(h.services);
      rs.capture = () async => image;
      rs.finish = (source, annotations) async => EncodedScreenshot(
        bytes: Uint8List.fromList(List.filled(annotations.length + 10, 7)),
        mimeType: 'image/png',
        width: source.width,
        height: source.height,
      );
      await openReport(tester);
    }

    Future<void> coverSomething(WidgetTester tester) async {
      await tester.ensureVisible(key(BoardReportKeys.addScreenshot));
      await tester.pumpAndSettle();
      await tester.tap(key(BoardReportKeys.addScreenshot));
      await tester.pumpAndSettle();
      expect(key(ScreenshotEditorKeys.dialog), findsOneWidget);
      final origin = tester.getTopLeft(key(ScreenshotEditorKeys.canvas));
      final g = await tester.startGesture(origin + const Offset(10, 10));
      await g.moveTo(origin + const Offset(40, 30));
      await g.moveTo(origin + const Offset(80, 60));
      await g.up();
      await tester.pump();
      await tester.tap(key(ScreenshotEditorKeys.done));
      await tester.pumpAndSettle();
    }

    testWidgets('when added and posted then it is uploaded before the post, '
        'in order', (tester) async {
      await openWithCapture(tester);
      await coverSomething(tester);

      expect(key(BoardReportKeys.thumbnail), findsOneWidget);
      expect(key(BoardReportKeys.editScreenshot), findsOneWidget);
      expect(key(BoardReportKeys.removeScreenshot), findsOneWidget);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');
      board.log.clear();
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      expect(board.log.where((l) => l != 'similar'), [
        'createScreenshotUpload image/png 11',
        'upload upload-description 11',
        'complete',
        'createPost',
      ]);
      expect(board.posted.single.screenshotFileUuid, isNotNull);
      await settle(tester);
    });

    testWidgets('when editing again then the annotations are still there', (
      tester,
    ) async {
      await openWithCapture(tester);
      await coverSomething(tester);

      await tester.ensureVisible(key(BoardReportKeys.editScreenshot));
      await tester.pumpAndSettle();
      await tester.tap(key(BoardReportKeys.editScreenshot));
      await tester.pumpAndSettle();

      final editor = tester.state<ScreenshotEditorState>(
        find.byType(ScreenshotEditor),
      );
      expect(editor.annotations.single, isA<CoverAnnotation>());
      await tester.tap(key(ScreenshotEditorKeys.cancel));
      await tester.pumpAndSettle();
      expect(dialog(tester).screenshot!.annotations, hasLength(1));
      await settle(tester);
    });

    testWidgets('when removed then nothing is uploaded', (tester) async {
      await openWithCapture(tester);
      await coverSomething(tester);

      await tester.ensureVisible(key(BoardReportKeys.removeScreenshot));
      await tester.pumpAndSettle();
      await tester.tap(key(BoardReportKeys.removeScreenshot));
      await tester.pumpAndSettle();
      expect(key(BoardReportKeys.thumbnail), findsNothing);
      expect(key(BoardReportKeys.addScreenshot), findsOneWidget);
      await enterField(
        tester,
        field(BoardReportField.title),
        'Crash on paste now',
      );
      await enterField(tester, field(BoardReportField.happened), 'Crash');
      await tester.tap(key(BoardReportKeys.post));
      await tester.pumpAndSettle();

      expect(board.log.where((l) => l.startsWith('upload')), isEmpty);
      expect(board.posted.single.screenshotFileUuid, isNull);
      await settle(tester);
    });
  });

  group('Given the layout', () {
    for (final b in Brightness.values) {
      testWidgets('when shown in ${b.name} at 1280 px then it is 640 wide '
          'and accessible', (tester) async {
        final semantics = tester.ensureSemantics();
        await openReport(tester, brightness: b);

        expect(tester.getSize(key(BoardReportKeys.dialog)).width, 640);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });

      testWidgets('when shown in ${b.name} below 600 px then it is full '
          'screen and nothing overflows', (tester) async {
        await openReport(tester, brightness: b, size: const Size(360, 720));

        expect(
          tester.getSize(key(BoardReportKeys.dialog)),
          const Size(360, 720),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
