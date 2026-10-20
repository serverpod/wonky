import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write/features/publish/submission_commands.dart';
import 'package:wonky_write/features/publish/submission_title_actions.dart';

import '../document/support/session_harness.dart' as session;
import '../screen/support/screen_harness.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

void main() {
  final uuid = UuidValue.fromString(session.itemUuid);

  Future<ScreenHarness> open(
    WidgetTester tester, {
    SubmissionView? view,
    String markdown = '# Faster CI\n\nHello\n',
  }) async {
    final h = await ScreenHarness.open(tester, markdown: markdown);
    final repo = h.session.publications;
    if (view != null) repo.submissions[uuid] = view;
    h.services.registry.registerAll(writeSubmissionCommands(h.services));
    h.doc.submission.start();
    await h.pump(
      tester,
      Center(
        child: SubmissionTitleActions(services: h.services, doc: h.doc),
      ),
    );
    await tester.runAsync(() => h.doc.submission.refresh());
    await tester.pumpAndSettle();
    return h;
  }

  group('Given a document without a submission', () {
    testWidgets('then nothing shows and Submit is disabled', (tester) async {
      final h = await open(tester);

      expect(_key('write.submission.submit'), findsNothing);
      expect(_key('write.submission.chip'), findsNothing);
      expect(
        h.services.dispatcher.stateOf('write.submission.submit').enabled,
        isFalse,
      );
      await h.dispose(tester);
    });
  });

  group('Given a draft story', () {
    testWidgets('then Submit shows without a status chip', (tester) async {
      final h = await open(tester, view: FakePublicationRepository.view(uuid));

      expect(_key('write.submission.submit'), findsOneWidget);
      expect(_key('write.submission.chip'), findsNothing);
      await h.dispose(tester);
    });

    testWidgets('when submitting then the title is the document\'s name and '
        'the chip shows In review', (tester) async {
      final h = await open(tester, view: FakePublicationRepository.view(uuid));

      await tester.tap(_key('write.submission.submit'));
      await tester.pumpAndSettle();
      expect(_key('dialog.submit'), findsOneWidget);
      await tester.tap(_key('dialog.submit.submit'));
      await tester.pumpAndSettle();

      final repo = h.session.publications;
      expect(repo.calls, contains('submit'));
      expect(repo.lastValues!.title, 'Plan');
      expect(find.text('In review'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('when offline then Submit is disabled with a reason', (
      tester,
    ) async {
      final h = await open(tester, view: FakePublicationRepository.view(uuid));

      h.services.connectivity.forceOffline(true);
      await tester.pump();

      final state = h.services.dispatcher.stateOf('write.submission.submit');
      expect(state.enabled, isFalse);
      expect(state.disabledReason, 'Submitting needs a connection.');
      h.services.connectivity.forceOffline(false);
      await h.dispose(tester);
    });
  });

  group('Given a story with changes requested', () {
    testWidgets('then the chip shows the status and the popover the message', (
      tester,
    ) async {
      final h = await open(
        tester,
        view: FakePublicationRepository.view(
          uuid,
          status: SubmissionStatus.changesRequested,
          lastSubmittedRevision: 0,
          lastMessage: 'Add an intro.',
        ),
      );

      expect(find.text('Changes requested'), findsOneWidget);
      await tester.tap(_key('write.submission.chip'));
      await tester.pumpAndSettle();

      expect(_key('write.submission.popover'), findsOneWidget);
      expect(find.text('Add an intro.'), findsOneWidget);
      expect(_key('write.submission.withdraw'), findsOneWidget);
      await h.dispose(tester);
    });
  });

  group('Given a declined story', () {
    testWidgets('then Submit is hidden', (tester) async {
      final h = await open(
        tester,
        view: FakePublicationRepository.view(
          uuid,
          status: SubmissionStatus.declined,
        ),
      );

      expect(_key('write.submission.submit'), findsNothing);
      expect(find.text('Declined'), findsOneWidget);
      await h.dispose(tester);
    });
  });

  group('Given a published story', () {
    testWidgets('when disconnecting then undo connects it again', (
      tester,
    ) async {
      final h = await open(
        tester,
        view: FakePublicationRepository.view(
          uuid,
          status: SubmissionStatus.published,
          publicUrl: 'https://blog.example.com/p',
        ),
      );

      await tester.runAsync(
        () => h.services.dispatcher.invoke(
          'write.submission.disconnect',
          source: InvocationSource.ui,
        ),
      );
      await tester.pumpAndSettle();
      expect(h.doc.submission.hasSubmission, isFalse);

      await tester.runAsync(() => h.services.undo.undo());
      await tester.runAsync(() => h.doc.submission.refresh());
      await tester.pumpAndSettle();

      expect(h.session.publications.calls, ['disconnect', 'reconnect']);
      expect(h.doc.submission.hasSubmission, isTrue);
      await h.dispose(tester);
    });
  });
}
