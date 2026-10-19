@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/platform/revlog/rev_file_state.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_service.dart';
import 'package:wonky_server/src/slides/headless/headless_deck.dart';
import 'package:wonky_server/src/slides/revlog/slides_rev_binding.dart';
import 'package:wonky_slides_core/ops.dart' show DeleteElements;

import '../../support/role_matrix.dart';
import '../../support/slides_rev_hooks.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Comments on slides and elements (Slides 09 §3, SL-38): `slide` and
/// `element` anchors, orphaning by the `comments` hook and revival,
/// notification extras, the role matrix.
void main() {
  withWonkyServerpod('Given a presentation with a commenter', (
    sessionBuilder,
    endpoints,
  ) {
    late Session server;
    late TestUser anna;
    late TestUser bo;
    late DriveItemView deck;
    late String slideId;
    late String elementId;
    var edits = 0;

    SlidesRevHooks.install();
    setUp(() async {
      server = sessionBuilder.build();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      deck = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Launch',
        null,
      );
      await TestDrive.share(endpoints, deck, anna, bo, AccessRole.commenter);
      final db = server;
      final slide = (await Slide.db.find(
        db,
        where: (t) => t.deckId.equals(deck.uuid),
      )).single;
      slideId = slide.id.uuid;
      elementId = (await SlideElement.db.find(
        db,
        where: (t) => t.slideId.equals(slide.id),
        orderBy: (t) => t.id,
      )).first.id.uuid;
    });

    Future<CommentThreadView> create(
      CommentAnchorKind kind,
      Map<String, Object?> anchor, {
      TestUser? as,
      List<int> mentions = const [],
    }) => endpoints.comment.createThread(
      (as ?? bo).endpointSession,
      const Uuid().v7obj(),
      deck.uuid,
      kind,
      jsonEncode({'v': 1, ...anchor}),
      'Slide 1',
      'Look here',
      mentions,
      null,
    );

    /// Commits an op with [summary] (a trivial deck change) and runs the
    /// hooks.
    Future<void> consume(Map<String, Object?> summary) async {
      final binding = SlidesRevBinding.instance;
      final state = (await RevFileStates.of(server, binding, deck.uuid))!;
      await RevLogService.submitServerChange(
        server,
        binding: binding,
        state: state,
        submitter: RevSubmitter.of(anna.actor),
        actorKind: 'user',
        label: 'Delete',
        changes: [
          RowChange.update(
            'deck',
            deck.uuid.uuid,
            {'footerText': null},
            {'footerText': 'Edit ${edits++}'},
          ),
        ],
        summary: summary,
      );
      await SlidesRevHooks.drain(server, deck.uuid);
    }

    Future<CommentThreadView> reread(CommentThreadView t) =>
        endpoints.comment.getThread(anna.endpointSession, t.uuid);

    test('when a commenter comments on a slide and an element then both '
        'threads are listed with their anchor kinds', () async {
      await create(CommentAnchorKind.slide, {'slideId': slideId});
      await create(CommentAnchorKind.element, {
        'slideId': slideId,
        'elementId': elementId,
      });

      final threads = await endpoints.comment.listThreads(
        anna.endpointSession,
        deck.uuid,
        CommentFilter.all,
      );

      expect(threads.map((t) => t.anchorKind), [
        CommentAnchorKind.slide,
        CommentAnchorKind.element,
      ]);
    });

    test(
      'when the anchored element is deleted then its thread is orphaned '
      'with the element as reason, and undoing the deletion revives it',
      () async {
        final t = await create(CommentAnchorKind.element, {
          'slideId': slideId,
          'elementId': elementId,
        });

        await consume({
          'deleted': {
            'elements': [elementId],
          },
        });
        final orphaned = await reread(t);
        await consume({
          'revived': {
            'elements': [elementId],
          },
        });
        final revived = await reread(t);

        expect(orphaned.status, CommentStatus.orphaned);
        expect(jsonDecode(orphaned.orphanReasonJson!), {
          'kind': 'element',
          'id': elementId,
          'revision': isA<int>(),
        });
        expect(revived.status, CommentStatus.open);
      },
    );

    test('when the slide is deleted then slide and element threads are '
        'orphaned with the slide as reason', () async {
      final s = await create(CommentAnchorKind.slide, {'slideId': slideId});
      final e = await create(CommentAnchorKind.element, {
        'slideId': slideId,
        'elementId': elementId,
      });

      await consume({
        'deleted': {
          'slides': [slideId],
          'elements': [elementId],
        },
      });

      for (final t in [s, e]) {
        final now = await reread(t);
        expect(now.status, CommentStatus.orphaned);
        expect(jsonDecode(now.orphanReasonJson!)['kind'], 'slide');
      }
    });

    test('when only the slide hint of an element anchor is deleted (the '
        'element moved away) then the thread stays open', () async {
      final t = await create(CommentAnchorKind.element, {
        'slideId': slideId,
        'elementId': elementId,
      });

      await consume({
        'deleted': {
          'slides': [slideId],
        },
      });

      expect((await reread(t)).status, CommentStatus.open);
    });

    test('when a resolved thread loses its element then it stays '
        'resolved', () async {
      final t = await create(CommentAnchorKind.element, {
        'slideId': slideId,
        'elementId': elementId,
      });
      await endpoints.comment.resolve(bo.endpointSession, t.uuid);

      await consume({
        'deleted': {
          'elements': [elementId],
        },
      });

      expect((await reread(t)).status, CommentStatus.resolved);
    });

    test('when an orphaned thread is re-anchored (cut & paste) then it is '
        'open on the new element', () async {
      final t = await create(CommentAnchorKind.element, {
        'slideId': slideId,
        'elementId': elementId,
      });
      await consume({
        'deleted': {
          'elements': [elementId],
        },
      });

      final moved = await endpoints.comment.updateAnchor(
        bo.endpointSession,
        t.uuid,
        jsonEncode({'v': 1, 'slideId': slideId, 'elementId': 'new-el'}),
      );

      expect(moved.status, CommentStatus.open);
      expect(jsonDecode(moved.anchorJson)['elementId'], 'new-el');
    });

    test('when the deck is copied with comments then the copies anchor to '
        'the copied slide and element', () async {
      await create(CommentAnchorKind.element, {
        'slideId': slideId,
        'elementId': elementId,
      });

      final copy = await endpoints.drive.copy(
        anna.endpointSession,
        deck.uuid,
        'Copy',
        null,
        true,
        false,
      );
      final threads = await endpoints.comment.listThreads(
        anna.endpointSession,
        copy.uuid,
        CommentFilter.all,
      );

      final a = jsonDecode(threads.single.anchorJson) as Map;
      final db = server;
      final slide = (await Slide.db.find(
        db,
        where: (t) => t.deckId.equals(copy.uuid),
      )).single;
      expect(a['slideId'], slide.id.uuid);
      expect(a['elementId'], isNot(elementId));
      final element = await SlideElement.db.findById(
        db,
        UuidValue.fromString(a['elementId'] as String),
      );
      expect(element?.slideId, slide.id);
    });

    test(
      'when a headless deletion of the element is reverted then the change '
      'log lists it as revived and the orphaned thread is open again',
      () async {
        final t = await create(CommentAnchorKind.element, {
          'slideId': slideId,
          'elementId': elementId,
        });
        final headless = await const SlidesHeadlessProvider().open(
          HeadlessDeckContext(anna.session, anna.actor),
          deck.uuid.uuid,
        );
        final w = await headless.write(DeleteElements([elementId]));
        await SlidesRevHooks.drain(server, deck.uuid);
        final orphaned = await reread(t);

        await endpoints.slides.revertChange(anna.endpointSession, w.changeId!);
        await SlidesRevHooks.drain(server, deck.uuid);
        final revived = await reread(t);

        expect(orphaned.status, CommentStatus.orphaned);
        expect(revived.status, CommentStatus.open);
        HeadlessFileCache.clear();
      },
    );

    test('when a commenter mentions the owner then the notification names '
        'the slide number and title', () async {
      await create(
        CommentAnchorKind.element,
        {'slideId': slideId, 'elementId': elementId},
        mentions: [anna.id],
      );

      final list = await endpoints.notification.list(
        anna.endpointSession,
        null,
        10,
        false,
      );
      final payload = jsonDecode(
        list.items
            .firstWhere((n) => n.kind == NotificationKind.mention)
            .payload,
      );

      expect(payload['slideNumber'], 1);
      expect(payload['slideTitle'], isA<String>());
      expect(payload['threadUuid'], isA<String>());
    });
  });

  withWonkyServerpod('Given element comments on a shared presentation', (
    sessionBuilder,
    endpoints,
  ) {
    forEachRole(
      'Given a presentation',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor, AccessRole.commenter},
      setup: (owner) => endpoints.drive.createPresentation(
        owner.endpointSession,
        null,
        'Deck',
        null,
      ),
      act: (caller, c) => endpoints.comment.createThread(
        caller,
        const Uuid().v7obj(),
        c.item.uuid,
        CommentAnchorKind.element,
        '{"v":1,"slideId":"s","elementId":"e"}',
        null,
        'Hi',
        const [],
        null,
      ),
    );
  });
}
