@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show PageSetup;
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/drive_trash.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';

import 'package:wonky_server/src/platform/drive/drive_events.dart';
import 'package:wonky_server/src/write/themes/builtin_theme_ids.dart';

import '../../support/role_matrix.dart';
import '../../support/streams.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Future<List<String>> _names(
  TestEndpoints endpoints,
  TestUser user, {
  UuidValue? folder,
  DriveView view = DriveView.folder,
}) async {
  final page = await endpoints.drive.list(
    user.endpointSession,
    folder,
    DriveListFilter(view: view),
    DriveSort(
      field: DriveSortField.name,
      descending: false,
      foldersFirst: true,
    ),
    null,
    100,
  );
  return [for (final i in page.items) i.name];
}

void main() {
  withWonkyServerpod('Given an empty drive', (sessionBuilder, endpoints) {
    late TestUser anna;
    setUp(
      () async => anna = await TestUsers.create(sessionBuilder, name: 'Anna'),
    );

    test(
      'when creating a folder and a document then both are listed, folders first',
      () async {
        await TestDrive.document(endpoints, anna, name: 'Alpha');
        await TestDrive.folder(endpoints, anna, name: 'Zeta');

        expect(await _names(endpoints, anna), ['Zeta', 'Alpha']);
      },
    );

    test(
      'when creating a document with Markdown then the content is stored',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          markdown: '# Title\n\nHello **world**',
        );

        final snapshot = await endpoints.document.getSnapshot(
          anna.endpointSession,
          doc.contentRef!,
          null,
        );

        expect(snapshot.revision, 1);
        expect(snapshot.deltaJson, contains('"header":1'));
        expect(snapshot.deltaJson, contains('"bold":true'));
      },
    );

    test(
      'when creating a document twice with the same documentUuid then one item exists',
      () async {
        final docUuid = const Uuid().v7obj();
        final first = await endpoints.drive.createDocument(
          anna.endpointSession,
          null,
          'Offline',
          null,
          null,
          documentUuid: docUuid,
        );
        final second = await endpoints.drive.createDocument(
          anna.endpointSession,
          null,
          'Offline',
          null,
          null,
          documentUuid: docUuid,
        );

        expect(second.uuid, first.uuid);
        expect(await _names(endpoints, anna), ['Offline']);
      },
    );

    group('when creating documents (T-1)', () {
      Future<Map<String, dynamic>> pageSetupOf(DriveItemView doc) async {
        final session = sessionBuilder.build();
        final item = await DriveItem.db.findFirstRow(
          session,
          where: (t) => t.uuid.equals(doc.uuid),
        );
        final row = await Document.db.findFirstRow(
          session,
          where: (t) => t.itemId.equals(item!.id),
        );
        return (jsonDecode(row!.pageSetupJson) as Map).cast<String, dynamic>();
      }

      test('then a blank document is Pageless with the default page '
          'setup', () async {
        final doc = await TestDrive.document(endpoints, anna);

        final setup = await pageSetupOf(doc);
        expect(setup['layout'], 'pageless');
        expect(
          PageSetup.fromJson(setup),
          PageSetup.fromJson(
            PageSetup.defaultsFor('en').toJson()..['layout'] = 'pageless',
          ),
        );
      });

      test('then documents from a built-in template or Markdown are '
          'Pageless', () async {
        final template = BuiltinTemplates.byKey('write.meeting-notes');
        final fromTemplate = await endpoints.drive.createDocument(
          anna.endpointSession,
          null,
          'Notes',
          template.uuid,
          null,
        );
        final fromMarkdown = await TestDrive.document(
          endpoints,
          anna,
          markdown: '# Hi',
        );

        expect((await pageSetupOf(fromTemplate))['layout'], 'pageless');
        expect((await pageSetupOf(fromMarkdown))['layout'], 'pageless');
      });

      test('then a user who chose Pages as the default layout gets '
          'Pages', () async {
        await endpoints.user.updatePreferences(
          anna.endpointSession,
          UserPreferencesPatch(writeDefaults: jsonEncode({'pageless': false})),
        );

        final doc = await TestDrive.document(endpoints, anna);

        expect((await pageSetupOf(doc))['layout'], 'pages');
      });
    });

    test(
      'when creating from a built-in template then its content is used',
      () async {
        final template = BuiltinTemplates.byKey('write.meeting-notes');
        final doc = await endpoints.drive.createDocument(
          anna.endpointSession,
          null,
          'Notes',
          template.uuid,
          null,
        );

        final snapshot = await endpoints.document.getSnapshot(
          anna.endpointSession,
          doc.contentRef!,
          null,
        );
        expect(snapshot.deltaJson, contains('Action items'));

        // The template's theme comes along.
        final session = sessionBuilder.build();
        final item = await DriveItem.db.findFirstRow(
          session,
          where: (t) => t.uuid.equals(doc.uuid),
        );
        final row = await Document.db.findFirstRow(
          session,
          where: (t) => t.itemId.equals(item!.id),
        );
        expect(row!.themeId, BuiltinThemeIds.forKey(template.themeKey!));
      },
    );

    test(
      'when listing document templates then built-ins are returned',
      () async {
        final templates = await endpoints.drive.listTemplates(
          anna.endpointSession,
          DriveItemKind.document,
        );

        expect(templates.map((t) => t.key), contains('write.meeting-notes'));
        expect(
          templates.every((t) => t.kind == DriveItemKind.document),
          isTrue,
        );
        expect(templates.map((t) => t.key), isNot(contains('write.welcome')));
        expect(templates.every((t) => t.previewStyle != null), isTrue);
      },
    );

    test('when naming an item with a slash then it is refused', () async {
      await expectLater(
        TestDrive.folder(endpoints, anna, name: 'a/b'),
        throwsA(isA<WonkyException>()),
      );
    });
  });

  withWonkyServerpod('Given nested folders', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView parent;
    late DriveItemView child;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder);
      parent = await TestDrive.folder(endpoints, anna, name: 'Parent');
      child = await TestDrive.folder(
        endpoints,
        anna,
        name: 'Child',
        parentUuid: parent.uuid,
      );
    });

    test(
      'when moving a folder into its child then a cycle error is thrown',
      () async {
        await expectLater(
          endpoints.drive.move(anna.endpointSession, [parent.uuid], child.uuid),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.cycle,
            ),
          ),
        );
      },
    );

    test(
      'when moving a document into the child then it is listed there',
      () async {
        final doc = await TestDrive.document(endpoints, anna, name: 'Doc');

        await endpoints.drive.move(anna.endpointSession, [
          doc.uuid,
        ], child.uuid);

        expect(await _names(endpoints, anna, folder: child.uuid), ['Doc']);
        final path = await endpoints.drive.path(anna.endpointSession, doc.uuid);
        expect(path.map((p) => p.name), ['Parent', 'Child']);
      },
    );

    test(
      'when trashing the parent then descendants are trashed and restored together',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          name: 'Inside',
          parentUuid: child.uuid,
        );

        await endpoints.drive.trash(anna.endpointSession, [parent.uuid]);
        final trashed = await endpoints.drive.get(
          anna.endpointSession,
          doc.uuid,
        );
        final trashView = await _names(endpoints, anna, view: DriveView.trash);
        await endpoints.drive.restore(anna.endpointSession, [parent.uuid]);
        final restored = await endpoints.drive.get(
          anna.endpointSession,
          doc.uuid,
        );

        expect(trashed.trashedAt, isNotNull);
        expect(trashView, ['Parent']);
        expect(restored.trashedAt, isNull);
      },
    );

    test(
      'when deleting forever without trashing first then it is refused',
      () async {
        await expectLater(
          endpoints.drive.deletePermanently(anna.endpointSession, [
            parent.uuid,
          ]),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test('when emptying the trash then the items are gone', () async {
      await endpoints.drive.trash(anna.endpointSession, [parent.uuid]);

      final count = await endpoints.drive.emptyTrash(anna.endpointSession);

      expect(count, 1);
      await expectLater(
        endpoints.drive.get(anna.endpointSession, child.uuid),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when the trash retention passed then the purge job deletes items',
      () async {
        await endpoints.drive.trash(anna.endpointSession, [parent.uuid]);

        final purged = await DriveTrash.purgeExpiredTrash(
          sessionBuilder.build(),
          now: clock.now().toUtc().add(const Duration(days: 31)),
        );

        expect(purged, greaterThanOrEqualTo(2));
        expect(await _names(endpoints, anna, view: DriveView.trash), isEmpty);
      },
    );
  });

  withWonkyServerpod('Given documents', (sessionBuilder, endpoints) {
    late TestUser anna;
    setUp(() async => anna = await TestUsers.create(sessionBuilder));

    test('when starring a document then it is in the starred view', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Star me');
      await TestDrive.document(endpoints, anna, name: 'Plain');

      await endpoints.drive.setStarred(anna.endpointSession, doc.uuid, true);

      expect(await _names(endpoints, anna, view: DriveView.starred), [
        'Star me',
      ]);
    });

    test('when renaming then the new name is returned', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Old');

      final renamed = await endpoints.drive.rename(
        anna.endpointSession,
        doc.uuid,
        ' New name ',
      );

      expect(renamed.name, 'New name');
    });

    test(
      'when searching for a word in the content then the document is found',
      () async {
        await TestDrive.document(
          endpoints,
          anna,
          name: 'Plans',
          markdown: 'The quarterly roadmap',
        );
        await TestDrive.document(endpoints, anna, name: 'Other');

        final result = await endpoints.drive.search(
          anna.endpointSession,
          'roadm',
          DriveSearchFilters(),
          null,
          20,
        );

        expect(result.items.map((i) => i.name), ['Plans']);
      },
    );

    test(
      "when another user searches then they do not find the owner's items",
      () async {
        await TestDrive.document(endpoints, anna, name: 'Secret plans');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');

        final result = await endpoints.drive.search(
          bo.endpointSession,
          'secret',
          DriveSearchFilters(),
          null,
          20,
        );

        expect(result.items, isEmpty);
      },
    );

    test(
      'when copying a document then the copy has the same content',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          markdown: 'Copy me',
        );

        final copy = await endpoints.drive.copy(
          anna.endpointSession,
          doc.uuid,
          'Copy',
          null,
          false,
          false,
        );
        final snapshot = await endpoints.document.getSnapshot(
          anna.endpointSession,
          copy.contentRef!,
          null,
        );

        expect(copy.uuid, isNot(doc.uuid));
        expect(snapshot.deltaJson, contains('Copy me'));
      },
    );

    test('when watching and renaming then a change event arrives', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Watched');
      final probeUuid = const Uuid().v4obj();
      final events = await subscribed(
        endpoints.drive.watch(anna.endpointSession),
        () => anna.session.messages.postMessage(
          DriveEvents.channel(anna.id),
          DriveChangeSignal(kind: DriveChangeKind.updated, itemUuid: probeUuid),
        ),
      );

      await endpoints.drive.rename(anna.endpointSession, doc.uuid, 'Renamed');

      final event = await nextWhere(events, (e) => e.itemUuid == doc.uuid);
      await events.cancel();
      expect(event.kind, DriveChangeKind.updated);
      expect(event.item?.name, 'Renamed');
    });

    test('when opening a document then it is in the recent view', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Recent');

      await endpoints.drive.markOpened(anna.endpointSession, doc.uuid);

      expect(
        await _names(endpoints, anna, view: DriveView.recent),
        contains('Recent'),
      );
    });

    test(
      'when importing nothing then storage usage counts documents',
      () async {
        await TestDrive.document(endpoints, anna, markdown: 'abc');

        final usage = await endpoints.drive.storageUsage(anna.endpointSession);

        expect(usage.documents, 1);
        expect(usage.bytesUsed, greaterThan(0));
      },
    );
  });

  withWonkyServerpod('Given the drive permission matrix', (
    sessionBuilder,
    endpoints,
  ) {
    forEachRole(
      'Given a shared document and get',
      endpoints,
      sessionBuilder,
      allowed: {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      },
      act: (caller, c) => endpoints.drive.get(caller, c.item.uuid),
    );
    forEachRole(
      'Given a shared document and rename',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      act: (caller, c) => endpoints.drive.rename(caller, c.item.uuid, 'New'),
    );
    forEachRole(
      'Given a shared document and trash',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      act: (caller, c) => endpoints.drive.trash(caller, [c.item.uuid]),
    );
    forEachRole(
      'Given a trashed document and delete forever',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner},
      setup: (owner) async {
        final doc = await TestDrive.document(endpoints, owner);
        return doc;
      },
      act: (caller, c) async {
        await endpoints.drive.trash(c.owner.endpointSession, [c.item.uuid]);
        await endpoints.drive.deletePermanently(caller, [c.item.uuid]);
      },
    );
    forEachRole(
      'Given a shared folder and creating a document in it',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      setup: (owner) => TestDrive.folder(endpoints, owner),
      act: (caller, c) => endpoints.drive.createDocument(
        caller,
        c.item.uuid,
        'In folder',
        null,
        null,
      ),
    );
  });
}
