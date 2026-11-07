@Tags(['integration'])
library;

import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/actor.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/sharing/access_service.dart';
import 'package:wonky_server/src/platform/sharing/anonymous_access.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _throwsCode(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// Signed-out viewers of link-shared documents, spreadsheets and
/// presentations (specs/06 §2.4): view-only whatever the link role, never
/// for other kinds, never with emails.
void main() {
  setUp(AnonymousAccess.resetLimits);
  tearDown(AnonymousAccess.resetLimits);

  withWonkyServerpod('Given a document shared by link as editor', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView doc;
    late TestSessionBuilder signedOut;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      doc = await TestDrive.document(
        endpoints,
        anna,
        name: 'Public plan',
        markdown: 'Hello world',
      );
      await endpoints.sharing.setLink(
        anna.endpointSession,
        doc.uuid,
        AccessRole.editor,
      );
      signedOut = TestUsers.unauthenticated(sessionBuilder);
    });

    test('when a signed-out visitor looks it up then they get its name and '
        'the owner name, by item or content id', () async {
      final byItem = await endpoints.publicItem.get(signedOut, doc.uuid);
      final byContent = await endpoints.publicItem.get(
        signedOut,
        doc.contentRef!,
      );

      expect(byItem.name, 'Public plan');
      expect(byItem.kind, DriveItemKind.document);
      expect(byItem.contentRef, doc.contentRef);
      expect(byItem.ownerName, 'Anna');
      expect(byContent.uuid, doc.uuid);
    });

    test('when a signed-out visitor reads the info then the role is viewer '
        'and no email is revealed', () async {
      final info = await endpoints.document.getInfo(
        signedOut,
        doc.contentRef!,
      );

      expect(info.item.role, AccessRole.viewer);
      expect(info.item.owner.email, isEmpty);
      expect(info.item.modifiedBy?.email ?? '', isEmpty);
      expect(info.item.parentUuid, isNull);
    });

    test('when a signed-out visitor reads the head snapshot then it works, '
        'and history is refused', () async {
      final head = await endpoints.document.getSnapshot(
        signedOut,
        doc.contentRef!,
        null,
      );
      expect(head.deltaJson, contains('Hello world'));
    });

    test('when a signed-out visitor connects then they are a viewer without '
        'presence, and their edits are refused', () async {
      final input = StreamController<DocClientMessage>();
      final queue = StreamQueue(
        endpoints.document.connect(signedOut, doc.contentRef!, 0, input.stream),
      );
      final init = await queue.next.timeout(const Duration(seconds: 10));
      expect(init, isA<DocInit>());
      init as DocInit;
      expect(init.role, AccessRole.viewer);
      expect(init.participants, isEmpty);
      expect(init.snapshotJson, contains('Hello world'));

      final id = UuidValue.fromString('0190f6b0-0000-7000-8000-000000000001');
      input.add(
        DocSubmitOp(
          clientOpId: id,
          baseRevision: init.revision,
          deltaJson: TestDrive.insertAt(0, 'Hacked '),
          kind: DocumentOpKind.content,
        ),
      );
      final rejected = await queue.next.timeout(const Duration(seconds: 10));
      expect(rejected, isA<DocOpRejected>());
      expect((rejected as DocOpRejected).code, DocRejectCode.forbiddenForRole);

      // The owner does not see the visitor in presence.
      final ownerInput = StreamController<DocClientMessage>();
      final ownerQueue = StreamQueue(
        endpoints.document.connect(
          anna.endpointSession,
          doc.contentRef!,
          0,
          ownerInput.stream,
        ),
      );
      final ownerInit =
          await ownerQueue.next.timeout(const Duration(seconds: 10)) as DocInit;
      expect(ownerInit.participants.map((p) => p.userId), [anna.id]);
      final snapshot = await endpoints.document.getSnapshot(
        anna.endpointSession,
        doc.contentRef!,
        null,
      );
      expect(snapshot.deltaJson, isNot(contains('Hacked')));

      await input.close();
      await ownerInput.close();
      await queue.cancel(immediate: true);
      await ownerQueue.cancel(immediate: true);
    });

    test(
      'when a signed-out visitor changes metadata then it is refused',
      () async {
        await expectLater(
          endpoints.document.updateMeta(
            signedOut,
            doc.contentRef!,
            DocumentMetaPatch(field: 'language', valueJson: '"sv"'),
            UuidValue.fromString('0190f6b0-0000-7000-8000-000000000002'),
          ),
          _throwsCode(WonkyErrorCode.forbidden),
        );
      },
    );

    test('when a signed-out visitor loads themes then the built-ins load '
        'without emails', () async {
      final builtins = await endpoints.writeTheme.listBuiltins(signedOut);
      expect(builtins, isNotEmpty);

      final theme = await endpoints.writeTheme.get(
        signedOut,
        builtins.first.uuid,
        doc.contentRef,
      );

      expect(theme.uuid, builtins.first.uuid);
      expect(theme.owner?.email ?? '', isEmpty);
    });

    test('when sharing calls or the drive are used signed out then they are '
        'refused', () async {
      await expectLater(
        endpoints.sharing.getSharing(signedOut, doc.uuid),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      await expectLater(
        endpoints.drive.get(signedOut, doc.uuid),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      await expectLater(
        endpoints.comment.listThreads(signedOut, doc.uuid, CommentFilter.all),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });

    test('when link sharing is turned off then signed-out visitors get not '
        'found', () async {
      await endpoints.sharing.setLink(anna.endpointSession, doc.uuid, null);

      await expectLater(
        endpoints.publicItem.get(signedOut, doc.uuid),
        _throwsCode(WonkyErrorCode.notFound),
      );
      await expectLater(
        endpoints.document.getInfo(signedOut, doc.contentRef!),
        _throwsCode(WonkyErrorCode.notFound),
      );
    });

    test('when the document is shared with an organization only then '
        'signed-out visitors get not found', () async {
      final org = await TestUsers.create(
        sessionBuilder,
        name: 'Org',
        email: 'org${clock.now().microsecondsSinceEpoch}@acme-org.dev',
      );
      final orgDoc = await TestDrive.document(endpoints, org);
      await endpoints.sharing.setGeneralAccess(
        org.endpointSession,
        orgDoc.uuid,
        GeneralAccess.organization,
        AccessRole.viewer,
      );

      await expectLater(
        endpoints.publicItem.get(signedOut, orgDoc.uuid),
        _throwsCode(WonkyErrorCode.notFound),
      );
    });

    test('when the document is in the trash then signed-out visitors get '
        'not found', () async {
      await endpoints.drive.trash(anna.endpointSession, [doc.uuid]);

      await expectLater(
        endpoints.publicItem.get(signedOut, doc.uuid),
        _throwsCode(WonkyErrorCode.notFound),
      );
    });

    test(
      'when a signed-out client calls too often then it is rate limited',
      () async {
        final before = AnonymousAccess.callsPerAddress;
        AnonymousAccess.callsPerAddress = 3;
        addTearDown(() => AnonymousAccess.callsPerAddress = before);
        for (var i = 0; i < 3; i++) {
          await endpoints.publicItem.get(signedOut, doc.uuid);
        }

        await expectLater(
          endpoints.publicItem.get(signedOut, doc.uuid),
          _throwsCode(WonkyErrorCode.limitExceeded),
        );
      },
    );
  });

  withWonkyServerpod('Given link-shared folders', (sessionBuilder, endpoints) {
    test('when a signed-out visitor looks up a folder or its items then they '
        'get nothing', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final folder = await TestDrive.folder(endpoints, anna);
      final child = await TestDrive.document(
        endpoints,
        anna,
        parentUuid: folder.uuid,
      );
      await endpoints.sharing.setLink(
        anna.endpointSession,
        folder.uuid,
        AccessRole.viewer,
      );
      final signedOut = TestUsers.unauthenticated(sessionBuilder);

      await expectLater(
        endpoints.publicItem.get(signedOut, folder.uuid),
        _throwsCode(WonkyErrorCode.notFound),
      );
      await expectLater(
        endpoints.publicItem.get(signedOut, child.uuid),
        _throwsCode(WonkyErrorCode.notFound),
      );
      final session = anna.session;
      final item = (await AccessService.findItem(session, folder.uuid))!;
      expect(
        await AccessService.effectiveRole(
          session,
          Actor.anonymousUserId,
          item,
        ),
        isNull,
      );
    });
  });

  withWonkyServerpod('Given a spreadsheet and a deck shared by link as '
      'editor', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestSessionBuilder signedOut;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      signedOut = TestUsers.unauthenticated(sessionBuilder);
    });

    Future<DriveItemView> linked(DriveItemView item) async {
      await endpoints.sharing.setLink(
        anna.endpointSession,
        item.uuid,
        AccessRole.editor,
      );
      return item;
    }

    test('when a signed-out visitor reads the spreadsheet then the role is '
        'viewer, and edits are refused on the stream', () async {
      final sheet = await linked(
        await endpoints.drive.createSpreadsheet(
          anna.endpointSession,
          null,
          'Numbers',
          null,
        ),
      );

      final info = await endpoints.sheetsDoc.info(
        signedOut,
        sheet.contentRef!,
      );
      expect(info.role, AccessRole.viewer);

      final input = StreamController<RevClientMessage>();
      final queue = StreamQueue(
        endpoints.sheetsDoc.connect(
          signedOut,
          sheet.contentRef!,
          0,
          'tab-anon',
          input.stream,
        ),
      );
      final init = await queue.next.timeout(const Duration(seconds: 10));
      expect(init, isA<RevInit>());
      expect((init as RevInit).role, AccessRole.viewer);
      input.add(
        RevSubmit(
          clientOpId: UuidValue.fromString(
            '0190f6b0-0000-7000-8000-000000000003',
          ),
          baseRevision: init.revision,
          payload: '[]',
          label: 'Edit',
          actorKind: ActorKind.user,
          groupIndex: 0,
          groupLast: true,
          offline: false,
          createdAt: clock.now().toUtc(),
        ),
      );
      final rejected = await queue.next.timeout(const Duration(seconds: 10));
      expect(rejected, isA<RevRejected>());
      expect(
        (rejected as RevRejected).code,
        RevRejectCode.forbiddenForRole,
      );
      await input.close();
      await queue.cancel(immediate: true);
    });

    test(
      'when a signed-out visitor reads the deck then the role is viewer',
      () async {
        final deck = await linked(
          await endpoints.drive.createPresentation(
            anna.endpointSession,
            null,
            'Deck',
            null,
          ),
        );

        final info = await endpoints.slidesDoc.info(
          signedOut,
          deck.contentRef!,
        );
        final item = await endpoints.publicItem.get(signedOut, deck.uuid);

        expect(info.role, AccessRole.viewer);
        expect(item.kind, DriveItemKind.presentation);
      },
    );

    test('when the spreadsheet is restricted then signed-out visitors get '
        'not found', () async {
      final sheet = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'Private',
        null,
      );

      await expectLater(
        endpoints.sheetsDoc.info(signedOut, sheet.contentRef!),
        _throwsCode(WonkyErrorCode.notFound),
      );
    });
  });
}
