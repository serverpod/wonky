@Tags(['integration'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/versions/version_service.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/slides/headless/deck_text_claims.dart';
import 'package:wonky_server/src/slides/headless/headless_deck.dart';
import 'package:wonky_server/src/slides/versions/slides_version_provider.dart';
import 'package:wonky_slides_core/history.dart';
import 'package:wonky_slides_core/model.dart' show ElementKind, SlidesText;
import 'package:wonky_slides_core/ops.dart';

import '../../support/slides_rev_hooks.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

String _text(String s) => jsonEncode([
  {'insert': '$s\n'},
]);

/// Version history of decks (Slides 09 §4–§5, 12 §4 SL-39): capture,
/// snapshot index with authors (the ops between captures), restore as one
/// revertible change, copies and permissions.
void main() {
  withWonkyServerpod('Given a deck edited by Anna and Bo', (
    sessionBuilder,
    endpoints,
  ) {
    late Session server;
    late TestUser anna;
    late TestUser bo;
    late DriveItemView item;
    late String box;

    SlidesRevHooks.install();
    setUpAll(() {
      server = sessionBuilder.build();
      DeckTextClaims.probeWait = const Duration(milliseconds: 300);
    });

    tearDown(() {
      DeckTextClaims.clear();
      HeadlessFileCache.clear();
    });

    /// Runs the deck's post-commit hooks (versions, comments, activity).
    Future<void> drain() => SlidesRevHooks.drain(server, item.uuid);

    Future<ServerHeadlessDeck> open(TestUser u) =>
        const SlidesHeadlessProvider().open(
          HeadlessDeckContext(u.session, u.actor),
          item.uuid.uuid,
        );

    Future<String> boxText() async {
      final e = await SlideElement.db.findById(
        server,
        UuidValue.withValidation(box),
      );
      return SlidesText.plainText(e?.text).trim();
    }

    Future<int> slideCount() async => (await Slide.db.find(
      server,
      where: (t) => t.deckId.equals(item.uuid),
    )).length;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      item = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Pitch',
        null,
      );
      await TestDrive.share(endpoints, item, anna, bo, AccessRole.editor);
      final deck = await open(anna);
      final w = await deck.write(
        InsertElements(deck.model.slides.single.id, [
          ElementSpec(
            kind: ElementKind.text,
            x: 100,
            y: 100,
            width: 400,
            height: 100,
            columns: {'text': _text('Hello')},
          ),
        ]),
      );
      box = (w.plan.result['elementIds']! as List).single as String;
      await drain();
    });

    test('when a version is named then its snapshot holds the deck and its '
        'index lists the slides and who changed what', () async {
      final v0 = await endpoints.version.nameCurrent(
        anna.endpointSession,
        item.uuid,
        'Start',
      );
      await (await open(bo)).write(SetText(ElementText(box), _text('Bo')));
      await (await open(anna)).write(const AddSlides());
      await drain();

      final v1 = await endpoints.version.nameCurrent(
        anna.endpointSession,
        item.uuid,
        'After',
      );

      expect(v1.authors.map((u) => u.id), containsAll([anna.id, bo.id]));
      final row = (await ItemVersion.db.findById(server, v1.id))!;
      final snapshot = await SlidesVersionProvider.snapshotOf(server, row);
      final model = snapshot.toModel();
      expect(model.slides, hasLength(2));
      expect(SlidesText.plainText(model.element(box)!.text).trim(), 'Bo');
      final index = await SlidesSnapshotIndex.db.findFirstRow(
        server,
        where: (t) => t.itemVersionId.equals(v1.id),
      );
      expect(jsonDecode(index!.slidesJson), hasLength(2));
      final changes = SlidesVersionChanges.parse(index.changesJson);
      expect(changes.latestOfElement(box), bo.id);
      expect(changes.authors, containsAll([anna.id, bo.id]));
      final viaEndpoint = SlidesVersionChanges.parse(
        await endpoints.slidesVersion.changes(
          anna.endpointSession,
          item.uuid,
          v1.id,
        ),
      );
      expect(viaEndpoint.latestOfElement(box), bo.id);
      // The first version only names Anna's setup edits.
      final first = SlidesVersionChanges.parse(
        await endpoints.slidesVersion.changes(
          anna.endpointSession,
          item.uuid,
          v0.id,
        ),
      );
      expect(first.latestOfElement(box), anna.id);
    });

    test(
      'when edits stop for 5 minutes then an auto version is captured',
      () async {
        final d = (await DriveItem.db.findFirstRow(
          server,
          where: (t) => t.uuid.equals(item.uuid),
        ))!;
        final state = (await ItemVersionState.db.findFirstRow(
          server,
          where: (t) => t.itemId.equals(d.id!),
        ))!;
        expect(state.dirtySince, isNotNull);

        await VersionService.captureDue(
          server,
          now: state.lastEditAt.add(const Duration(minutes: 5, seconds: 1)),
        );

        final versions = await endpoints.version.list(
          anna.endpointSession,
          item.uuid,
          false,
        );
        expect(versions.single.kind, VersionKind.auto);
        expect(versions.single.storageKind, VersionStorage.snapshotFile);
      },
    );

    test(
      'when a version is restored then the deck equals it, a restore '
      'point is kept, and the restore reverts and reapplies as one change',
      () async {
        final v0 = await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'Start',
        );
        await (await open(
          anna,
        )).write(SetText(ElementText(box), _text('Edit')));
        await (await open(anna)).write(const AddSlides(count: 2));
        expect(await slideCount(), 3);

        final r = await endpoints.version.restore(
          anna.endpointSession,
          item.uuid,
          v0.id,
        );

        expect(r.restorePoint.kind, VersionKind.restorePoint);
        expect(r.changeId, isNotNull);
        expect(await boxText(), 'Hello');
        expect(await slideCount(), 1);
        final file = await RevFile.db.findFirstRow(
          server,
          where: (t) => t.fileUuid.equals(item.uuid),
        );
        final log = await RevOp.db.find(
          server,
          where: (t) => t.fileId.equals(file!.id!),
          orderBy: (t) => t.revision,
        );
        expect(log.last.label, startsWith('Restore version "Start"'));

        final undo = await endpoints.slides.revertChange(
          anna.endpointSession,
          r.changeId!,
        );
        expect(undo.skipped, isEmpty);
        expect(await boxText(), 'Edit');
        expect(await slideCount(), 3);

        final redo = await endpoints.slides.reapplyChange(
          anna.endpointSession,
          undo.changeId,
        );
        expect(redo.skipped, isEmpty);
        expect(await boxText(), 'Hello');
        expect(await slideCount(), 1);
      },
    );

    test(
      'when a version from before an element was deleted is restored '
      'then the comment thread orphaned by the deletion is open again',
      () async {
        final v0 = await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'Start',
        );
        final deck = await open(anna);
        final thread = await endpoints.comment.createThread(
          bo.endpointSession,
          const Uuid().v7obj(),
          item.uuid,
          CommentAnchorKind.element,
          jsonEncode({
            'v': 1,
            'slideId': deck.model.slides.single.id,
            'elementId': box,
          }),
          'Hello',
          'Check this',
          const [],
          null,
        );
        await deck.write(DeleteElements([box]));
        await drain();
        final orphaned = await endpoints.comment.getThread(
          anna.endpointSession,
          thread.uuid,
        );

        await endpoints.version.restore(anna.endpointSession, item.uuid, v0.id);
        await drain();
        final revived = await endpoints.comment.getThread(
          anna.endpointSession,
          thread.uuid,
        );

        expect(orphaned.status, CommentStatus.orphaned);
        expect(await boxText(), 'Hello');
        expect(revived.status, CommentStatus.open);
      },
    );

    test('when Bo edits after Anna restored then undoing the restore keeps '
        "Bo's text", () async {
      final v0 = await endpoints.version.nameCurrent(
        anna.endpointSession,
        item.uuid,
        'Start',
      );
      await (await open(anna)).write(SetText(ElementText(box), _text('Edit')));
      final r = await endpoints.version.restore(
        anna.endpointSession,
        item.uuid,
        v0.id,
      );
      await (await open(bo)).write(SetText(ElementText(box), _text('Bo')));

      final undo = await endpoints.slides.revertChange(
        anna.endpointSession,
        r.changeId!,
      );

      expect([for (final s in undo.skipped) s.column], ['text']);
      expect(await boxText(), 'Bo');
    });

    test('when a version is copied then a new presentation holds the '
        "version's content", () async {
      final v0 = await endpoints.version.nameCurrent(
        anna.endpointSession,
        item.uuid,
        'Start',
      );
      await (await open(anna)).write(const AddSlides(count: 2));

      final copy = await endpoints.slidesVersion.makeCopy(
        anna.endpointSession,
        item.uuid,
        v0.id,
        'Pitch (start)',
        null,
        false,
        false,
      );

      expect(copy.kind, DriveItemKind.presentation);
      expect(copy.name, 'Pitch (start)');
      expect(copy.uuid, isNot(item.uuid));
      final slides = await Slide.db.find(
        server,
        where: (t) => t.deckId.equals(copy.contentRef!),
      );
      expect(slides, hasLength(1));
      final deck = await Deck.db.findById(
        server,
        copy.contentRef!,
      );
      expect(deck!.title, 'Pitch (start)');
    });

    test(
      'when a viewer or a stranger asks for history then it is refused',
      () async {
        final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
        final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
        await TestDrive.share(endpoints, item, anna, vic, AccessRole.viewer);
        final v0 = await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'Start',
        );

        for (final u in [vic, eve]) {
          await expectLater(
            endpoints.version.list(u.endpointSession, item.uuid, false),
            throwsA(isA<WonkyException>()),
          );
          await expectLater(
            endpoints.version.restore(u.endpointSession, item.uuid, v0.id),
            throwsA(isA<WonkyException>()),
          );
          await expectLater(
            endpoints.slidesVersion.changes(
              u.endpointSession,
              item.uuid,
              v0.id,
            ),
            throwsA(isA<WonkyException>()),
          );
          await expectLater(
            endpoints.slidesVersion.makeCopy(
              u.endpointSession,
              item.uuid,
              v0.id,
              'Copy',
              null,
              false,
              false,
            ),
            throwsA(isA<WonkyException>()),
          );
        }
      },
    );

    test('when Anna edits two slides then her activity event lists the '
        'distinct slides once (09 §5)', () async {
      final deck = await open(anna);
      final first = deck.model.slides.single.id;
      await deck.write(SetText(ElementText(box), _text('One')));
      await (await open(anna)).write(SetText(ElementText(box), _text('Two')));
      await (await open(anna)).write(AddSlides(afterSlideId: first));
      await drain();

      final d = (await DriveItem.db.findFirstRow(
        server,
        where: (t) => t.uuid.equals(item.uuid),
      ))!;
      final events = await ActivityEvent.db.find(
        server,
        where: (t) =>
            t.itemId.equals(d.id!) &
            t.actorId.equals(anna.id) &
            t.type.equals(ActivityType.edited),
      );
      final summary = jsonDecode(events.single.summary) as Map;
      expect(summary['slideIds'], hasLength(2));
      expect(summary['slideIds'], contains(first));
    });
  });
}
