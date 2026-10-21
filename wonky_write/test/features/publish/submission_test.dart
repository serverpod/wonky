import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write/features/images/image_services.dart';
import 'package:wonky_write/features/publish/submission_commands.dart';
import 'package:wonky_write/features/publish/submission_title_actions.dart';
import 'package:wonky_write/features/publish/submit_dialog.dart';

import '../document/support/session_harness.dart' as session;
import '../screen/support/screen_harness.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

void main() {
  final uuid = UuidValue.fromString(session.itemUuid);

  Future<ScreenHarness> open(
    WidgetTester tester, {
    SubmissionView? view,
    String markdown = '# Faster CI\n\nHello\n',
    Brightness brightness = Brightness.light,
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
      brightness: brightness,
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

  group('Given a publication that asks for a cover image', () {
    /// A 1×1 PNG.
    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      ),
    );
    SubmissionView coverView({
      PublicationFieldMode mode = PublicationFieldMode.required,
    }) {
      final v = FakePublicationRepository.view(uuid);
      return v.copyWith(fields: v.fields.copyWith(coverImage: mode));
    }

    setUp(
      () =>
          debugPickCoverImage = () async =>
              PickedImage(name: 'cover.png', bytes: png, mimeType: 'image/png'),
    );
    tearDown(() => debugPickCoverImage = null);

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(_key('write.submission.submit'));
      await tester.pumpAndSettle();
    }

    for (final brightness in Brightness.values) {
      testWidgets('then the dialog (${brightness.name}) offers to upload one, '
          'with an empty themed thumbnail and no Remove', (tester) async {
        final h = await open(tester, view: coverView(), brightness: brightness);

        await openDialog(tester);

        expect(_key('dialog.submit.cover'), findsOneWidget);
        expect(_key('dialog.submit.cover.upload'), findsOneWidget);
        expect(_key('dialog.submit.cover.remove'), findsNothing);
        expect(find.text('Upload image'), findsOneWidget);
        expect(find.text('No cover'), findsOneWidget);
        final cs = ShadTheme.of(
          tester.element(_key('dialog.submit.cover')),
        ).colorScheme;
        final box = tester.widget<Container>(
          find.descendant(
            of: _key('dialog.submit.cover'),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          ),
        );
        expect((box.decoration! as BoxDecoration).color, cs.muted);
        await h.dispose(tester);
      });
    }

    testWidgets('when uploading an image and submitting then it is uploaded '
        'to the document and sent as the cover', (tester) async {
      final h = await open(tester, view: coverView());
      await openDialog(tester);

      await tester.tap(_key('dialog.submit.cover.upload'));
      await tester.pumpAndSettle();

      final upload = h.session.files.uploads.single;
      expect(upload.itemUuid, uuid);
      expect(upload.name, 'cover.png');
      expect(_key('dialog.submit.cover.preview'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
      expect(_key('dialog.submit.cover.remove'), findsOneWidget);
      // Not inserted into the document.
      expect(h.doc.editor.delta.toList().any((op) => op.data is Map), isFalse);

      await tester.tap(_key('dialog.submit.submit'));
      await tester.pumpAndSettle();

      expect(h.session.publications.lastValues!.coverImage, upload.fileUuid);
      await h.dispose(tester);
    });

    testWidgets('when removing the uploaded image then the story is '
        'submitted without a cover', (tester) async {
      final h = await open(
        tester,
        view: coverView(mode: PublicationFieldMode.optional),
      );
      await openDialog(tester);
      await tester.tap(_key('dialog.submit.cover.upload'));
      await tester.pumpAndSettle();

      await tester.tap(_key('dialog.submit.cover.remove'));
      await tester.pumpAndSettle();
      expect(_key('dialog.submit.cover.preview'), findsNothing);
      await tester.tap(_key('dialog.submit.submit'));
      await tester.pumpAndSettle();

      expect(h.session.publications.calls, contains('submit'));
      expect(h.session.publications.lastValues!.coverImage, isNull);
      await h.dispose(tester);
    });

    testWidgets('when the picker is cancelled then nothing is uploaded and a '
        'required cover blocks the submit', (tester) async {
      debugPickCoverImage = () async => null;
      final h = await open(tester, view: coverView());
      await openDialog(tester);

      await tester.tap(_key('dialog.submit.cover.upload'));
      await tester.pumpAndSettle();
      await tester.tap(_key('dialog.submit.submit'));
      await tester.pumpAndSettle();

      expect(h.session.files.uploads, isEmpty);
      expect(h.session.publications.calls, isNot(contains('submit')));
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
