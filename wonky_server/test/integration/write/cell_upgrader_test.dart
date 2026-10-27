@Tags(['integration'])
library;

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_server/src/platform/common/actor.dart';
import 'package:wonky_server/src/platform/common/models.dart' hide CellTable;
import 'package:wonky_server/src/write/ot/document_cache.dart';
import 'package:wonky_server/src/write/ot/document_store.dart';
import 'package:wonky_server/src/write/ot/ot_service.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../support/mcp_harness.dart';
import '../../support/test_doc_client.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// A table and a grid embed line inserted at the start, as documents
/// written before Write 12 hold them.
Delta _legacyInsert() => Delta()
  ..insert(
    const TableEmbed(
      id: 't1',
      align: [null, CellAlign.right],
      rows: [
        ['Name', 'Qty'],
        ['**Pens**', '3'],
      ],
    ).toInsert(),
  )
  ..insert('\n')
  ..insert(const GridEmbed(id: 'g1', items: ['Fast', 'Reliable']).toInsert())
  ..insert('\n');

/// Appends [change] to the op log of [item] like an old server did and
/// drops the cached state, so the next use loads the document. Returns
/// the new head revision.
Future<int> _storeLegacy(
  Session session,
  DriveItemView item,
  TestUser author,
  Delta change,
) async {
  final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
  final before = await DocumentStore.head(session, doc);
  final head = doc.headRevision;
  await DocumentOp.db.insertRow(
    session,
    DocumentOp(
      documentId: doc.id!,
      revision: head + 1,
      clientOpId: const Uuid().v7obj(),
      authorId: author.id,
      actorKind: ActorKind.user,
      kind: DocumentOpKind.content,
      baseRevision: head,
      deltaJson: jsonEncode(change.toJson()),
      inverseJson: jsonEncode(WonkyOt.invert(change, before).toJson()),
      createdAt: clock.now().toUtc(),
    ),
  );
  await Document.db.updateWhere(
    session,
    columnValues: (t) => [t.headRevision(head + 1)],
    where: (t) => t.id.equals(doc.id!),
  );
  DocumentCache.evict(item.contentRef!);
  return head + 1;
}

Future<Delta> _stored(Session session, DriveItemView item) async {
  final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
  return DocumentStore.head(session, doc);
}

Future<List<DocumentOp>> _ops(Session session, DriveItemView item) async {
  final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
  return DocumentOp.db.find(
    session,
    where: (t) => t.documentId.equals(doc.id!),
    orderBy: (t) => t.revision,
  );
}

/// The tables and grids of [content] in document order, as
/// `table <id>` / `grid <id>`.
List<String> _runs(Delta content) => [
  for (final r in CellRuns.of(WonkyDocument(content)))
    switch (r) {
      CellTable(:final id) => 'table $id',
      CellGrid(:final id) => 'grid $id',
      _ => '?',
    },
];

void main() {
  withWonkyServerpod('Given a document stored with legacy table and grid '
      'embeds', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView item;
    late int legacyHead;
    late Delta legacy;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, markdown: 'Intro');
      final session = sessionBuilder.build();
      legacyHead = await _storeLegacy(session, item, anna, _legacyInsert());
      legacy = await _stored(session, item);
    });

    test(
      'when the document is loaded then one system op upgrades the embeds '
      'to cell lines',
      () async {
        final client = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        await client.close();
        final session = sessionBuilder.build();
        final ops = await _ops(session, item);
        final stored = await _stored(session, item);

        expect(client.init.revision, legacyHead + 1);
        expect(CellUpgrade.hasLegacy(client.document), isFalse);
        expect(_runs(client.document), ['table t1', 'grid g1']);
        expect(DeltaUtils.equals(stored, client.document), isTrue);
        expect(
          ops.skip(legacyHead).map((o) => (o.actorKind, o.kind, o.authorId)),
          [(ActorKind.system, DocumentOpKind.system, null)],
        );
      },
    );

    test(
      'when the document is upgraded then its Markdown export is unchanged',
      () async {
        await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        ).then((c) => c.close());
        final stored = await _stored(sessionBuilder.build(), item);

        expect(
          const MarkdownCodec().exportMarkdown(stored),
          const MarkdownCodec().exportMarkdown(legacy),
        );
      },
    );

    test(
      'when the document is loaded a second time then nothing more is '
      'committed',
      () async {
        await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        ).then((c) => c.close());
        DocumentCache.evict(item.contentRef!);

        final again = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        await again.close();
        final ops = await _ops(sessionBuilder.build(), item);

        expect(again.init.revision, legacyHead + 1);
        expect(ops.length, legacyHead + 1);
      },
    );

    test(
      'when an MCP tool reads the document first then it edits the upgraded '
      'table by the embed id',
      () async {
        final mcp = await McpHarness.forUser(anna);

        final r = await mcp.call('write.update_table', {
          'document_uuid': docOf(item),
          'table': {'table_id': 't1'},
          'operations': [
            {'op': 'set_cell', 'row': 1, 'col': 1, 'markdown': '4'},
          ],
        });
        final stored = await _stored(sessionBuilder.build(), item);

        expect(r['revision'], legacyHead + 2);
        expect(CellUpgrade.hasLegacy(stored), isFalse);
        expect(
          const MarkdownCodec().exportMarkdown(stored),
          contains('| **Pens** | 4 |'),
        );
      },
    );

    test(
      'when a version from before the upgrade is restored then the restored '
      'embeds are upgraded again',
      () async {
        // Captured from the stored head: the document is not loaded yet.
        final version = await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'Legacy',
        );
        await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        ).then((c) => c.close());

        final result = await endpoints.version.restore(
          anna.endpointSession,
          item.uuid,
          version.id,
        );
        final session = sessionBuilder.build();
        final stored = await _stored(session, item);
        final ops = await _ops(session, item);

        expect(version.revision, legacyHead);
        expect(CellUpgrade.hasLegacy(stored), isFalse);
        expect(_runs(stored), ['table t1', 'grid g1']);
        expect(ops.map((o) => o.revision).last, result.revision! + 1);
        expect(ops.last.kind, DocumentOpKind.system);
      },
    );
  });

  withWonkyServerpod('Given a connected client on a document without legacy '
      'embeds', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView item;
    late TestDocClient client;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, markdown: 'Intro');
      client = await TestDocClient.connect(endpoints, anna, item.contentRef!);
    });
    tearDown(() => client.close());

    test(
      'when an old client commits a table embed then the upgrade follows as '
      'a system op that the client receives',
      () async {
        final head = client.revision;

        client.submitRaw(jsonEncode(_legacyInsert().toJson()));
        // The ack and the upgrade op may arrive in either order.
        DocAck? ack;
        DocRemoteOp? upgrade;
        while (ack == null || upgrade == null) {
          switch (await client.nextAny()) {
            case final DocAck m:
              ack = m;
            case final DocRemoteOp m:
              upgrade = m;
            default:
              break;
          }
        }
        await client.sideEffectsDone();
        final stored = await _stored(sessionBuilder.build(), item);
        final ops = await _ops(sessionBuilder.build(), item);

        expect(ack.revision, head + 1);
        expect(
          (
            upgrade.revision,
            upgrade.actorKind,
            upgrade.kind,
            upgrade.authorId,
          ),
          (head + 2, ActorKind.system, DocumentOpKind.system, null),
        );
        expect(CellUpgrade.hasLegacy(stored), isFalse);
        expect(_runs(stored), ['table t1', 'grid g1']);
        expect(ops.length, head + 2);
      },
    );

    test(
      'when a change that must commit at the head is based on an older '
      'revision then it is rejected instead of rebased',
      () async {
        client.edit(Delta()..insert('Hello '));
        await client.processUntilSynchronized();
        final session = sessionBuilder.build();
        final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
        final driveItem = (await DriveItem.db.findById(session, doc.itemId))!;
        final profile = (await UserProfile.db.findById(session, anna.id))!;

        final submit = OtService.submit(
          session,
          actor: Actor(
            userId: anna.id,
            authUserId: profile.authUserId,
            kind: ActorKind.system,
          ),
          document: doc,
          item: driveItem,
          role: Role.owner,
          clientOpId: const Uuid().v7obj(),
          baseRevision: client.revision - 1,
          deltaJson: TestDrive.insertAt(0, 'x'),
          kind: DocumentOpKind.system,
          atHead: true,
        );

        await expectLater(
          submit,
          throwsA(
            isA<OpRejection>().having(
              (r) => r.code,
              'code',
              DocRejectCode.rebaseTooOld,
            ),
          ),
        );
      },
    );

    test(
      'when a client commits ordinary text then no upgrade op is committed',
      () async {
        client.edit(Delta()..insert('Hello '));
        await client.processUntilSynchronized();

        final ops = await _ops(sessionBuilder.build(), item);

        expect(ops.length, client.revision);
        expect(ops.last.actorKind, ActorKind.user);
      },
    );
  });
}
