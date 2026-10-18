@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/platform/revlog/rev_file_state.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_service.dart';
import 'package:wonky_server/src/platform/revlog/rev_pages.dart';
import 'package:wonky_server/src/platform/revlog/rev_views.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'support/test_rev_binding.dart';

/// The RevLog sequencer on a test schema (RevLog spec 05 §3, §6–§9).
void main() {
  withWonkyServerpod('Given a RevLog file', (sessionBuilder, endpoints) {
    final binding = TestRevBinding.instance;
    late TestUser anna;
    late TestUser ben;
    late Session session;
    late DriveItem item;
    late TestFileIds ids;
    late RevFileState state;
    late RevFileLease lease;

    setUpAll(() async {
      await createTestTables(sessionBuilder.build());
      // Hooks are drained explicitly (drainNow) in these tests.
      RevHooks.debounce = const Duration(hours: 1);
    });

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
      session = sessionBuilder.build();
      item = await testItem(session, anna, 'Budget');
      await TestDrive.share(
        endpoints,
        await endpoints.drive.get(anna.endpointSession, item.uuid),
        anna,
        ben,
        AccessRole.editor,
      );
      ids = TestFileIds(item.uuid.uuid);
      await RevLogService.createFile(
        session,
        binding: binding,
        item: item,
        submitter: submitterOf(anna),
        initialChanges: ids.creation(title: 'Old name'),
      );
      state = (await RevFileStates.of(session, binding, item.uuid))!;
      lease = RevFileStates.retain(state);
    });
    tearDown(() async {
      lease.release();
      await RevHooks.idle();
    });

    Future<RevCommit> submit(
      List<RowChange> changes, {
      TestUser? as,
      int? base,
      String? clientOpId,
      Role role = Role.editor,
    }) => RevLogService.submit(
      session,
      binding: binding,
      state: state,
      cs: ChangeSet(
        clientOpId: clientOpId ?? const Uuid().v7(),
        baseRevision: base ?? state.revision,
        changes: changes,
      ),
      submitter: submitterOf(as ?? anna),
      connectionRole: role,
    );

    Future<Map<String, Object?>?> row(String table, String id) async {
      final rows = await session.db.unsafeQuery(
        'SELECT row_to_json(t)::text FROM "$table" t WHERE id = @id::uuid',
        parameters: QueryParameters.named({'id': id}),
      );
      return rows.isEmpty
          ? null
          : (jsonDecode(rows.first[0]! as String) as Map).cast();
    }

    test(
      'when the file is created then the rows are revision 1 and the title is the item name',
      () async {
        expect(state.revision, 1);
        final doc = await row('rl_doc', ids.doc);
        expect(doc!['title'], 'Budget');
        expect(doc['revision'], 1);
        final file = await RevFile.db.findById(session, state.fileId);
        expect(file!.initPending, isFalse);
        expect(jsonDecode(file.stats)['tables']['rl_row'], 4);
      },
    );

    test(
      'when a cell is set then it is committed with the next revision',
      () async {
        final c = await submit([ids.setCell(0, 0, 'n:1')]);
        expect(c.revision, 2);
        expect(c.duplicate, isFalse);
        expect(c.appliedEqualsSubmitted, isTrue);
        final cell = await row('rl_cell', ids.cell(0, 0));
        expect(cell!['content'], 'n:1');
        expect(cell['revision'], 2);
        final op = await RevOp.db.findFirstRow(
          session,
          where: (t) => t.fileId.equals(state.fileId) & t.revision.equals(2),
        );
        expect(op!.authorId, anna.id);
        expect(RevViews.decodeStored(binding.codec, op.payload!), hasLength(1));
      },
    );

    test(
      'when an op is resent then it is acknowledged as a duplicate',
      () async {
        final id = const Uuid().v7();
        final a = await submit([ids.setCell(0, 1, 'x')], clientOpId: id);
        final b = await submit([ids.setCell(0, 1, 'x')], clientOpId: id);
        expect(b.duplicate, isTrue);
        expect(b.revision, a.revision);
        expect(state.revision, a.revision);
      },
    );

    test(
      'when a row with listed and unlisted cells is deleted then every cell goes and the unlisted ones are reported',
      () async {
        await submit([ids.setCell(1, 0, 'a'), ids.setCell(1, 1, 'b')]);
        final rowCols = (await row('rl_row', ids.rows[1]))!;
        final c = await submit([
          RowChange.delete('rl_cell', ids.cell(1, 0), const {}),
          RowChange.delete('rl_row', ids.rows[1], {
            'sheetId': rowCols['sheetId'],
          }),
        ]);
        expect(await row('rl_cell', ids.cell(1, 0)), isNull);
        expect(await row('rl_cell', ids.cell(1, 1)), isNull);
        expect(await row('rl_row', ids.rows[1]), isNull);
        final outcome = jsonDecode(c.outcomeJson!) as Map;
        expect(outcome['cascaded'], hasLength(1));
        expect(c.appliedEqualsSubmitted, isFalse);
      },
    );

    test(
      'when a missing row is updated then the change is dropped and reported',
      () async {
        final c = await submit([
          RowChange.update('rl_row', const Uuid().v7(), const {}, {
            'height': 3.0,
          }),
        ]);
        final outcome = jsonDecode(c.outcomeJson!) as Map;
        expect(outcome['dropped'].single['reason'], 'rowMissing');
      },
    );

    test(
      'when another user overwrote the field then the conflict names them',
      () async {
        await submit([ids.setCell(2, 0, 'mine')]);
        await submit([
          RowChange.update(
            'rl_cell',
            ids.cell(2, 0),
            {'content': 'mine'},
            {'content': 'bens'},
          ),
        ], as: ben);
        final c = await submit([
          RowChange.update(
            'rl_cell',
            ids.cell(2, 0),
            {'content': 'mine'},
            {'content': 'annas'},
          ),
        ]);
        final conflict =
            (jsonDecode(c.outcomeJson!) as Map)['conflicts'].single;
        expect(conflict['theirs'], 'bens');
        expect(conflict['byUser'], ben.authUserId.uuid);
        expect((await row('rl_cell', ids.cell(2, 0)))!['content'], 'annas');
      },
    );

    test('when a viewer submits then it is rejected', () async {
      expect(
        () => submit([ids.setCell(0, 0, 'x')], role: Role.viewer),
        throwsA(
          isA<RevRejection>().having(
            (r) => r.reason,
            'reason',
            RevRejectReason.forbiddenForRole,
          ),
        ),
      );
    });

    test('when the base is ahead of the head then it is rejected', () async {
      expect(
        () => submit([ids.setCell(0, 0, 'x')], base: 99),
        throwsA(
          isA<RevRejection>().having(
            (r) => r.reason,
            'reason',
            RevRejectReason.unknownBase,
          ),
        ),
      );
    });

    test(
      'when an op names a row of another file then it is rejected and nothing is written',
      () async {
        final other = await testItem(session, anna, 'Other');
        final otherIds = TestFileIds(other.uuid.uuid);
        await RevLogService.createFile(
          session,
          binding: binding,
          item: other,
          submitter: submitterOf(anna),
          initialChanges: otherIds.creation(),
        );
        final before = state.revision;
        await expectLater(
          submit([
            RowChange.update('rl_row', otherIds.rows[0], const {}, {
              'height': 9.0,
            }),
          ]),
          throwsA(
            isA<RevRejection>().having(
              (r) => r.reason,
              'reason',
              RevRejectReason.invalidChange,
            ),
          ),
        );
        expect(state.revision, before);
        expect((await row('rl_row', otherIds.rows[0]))!['height'], isNull);
      },
    );

    test(
      'when pages are read then they cover the file at one revision',
      () async {
        await submit([ids.setCell(0, 0, 'p'), ids.setCell(3, 2, 'q')]);
        final file = (await RevFile.db.findById(session, state.fileId))!;
        final structure = await RevPages.page(
          session,
          binding,
          file,
          RevPageRequest(kind: RevPageKind.structure, maxRows: 100),
        );
        expect(structure.revision, state.revision);
        expect(structure.nextCursor, isNull);
        final rows = RevPageCodec.decode(
          binding.schema,
          RevCodec.gunzip(structure.body.buffer.asUint8List()),
        );
        expect(rows.where((r) => r.$1 == 'rl_row'), hasLength(4));
        expect(structure.coverage, contains('tbl:rl_row:-:+'));
        final cells = await RevPages.page(
          session,
          binding,
          file,
          RevPageRequest(
            kind: RevPageKind.cells,
            sheetId: UuidValue.fromString(ids.sheet),
            rowIds: [for (final r in ids.rows) UuidValue.fromString(r)],
            maxRows: 1000,
          ),
        );
        final cellRows = RevPageCodec.decode(
          binding.schema,
          RevCodec.gunzip(cells.body.buffer.asUint8List()),
        );
        expect(cellRows.map((r) => r.$2['content']).toSet(), {'p', 'q'});
        expect(cells.coverage, hasLength(4));
      },
    );

    test(
      'when pages are smaller than the file then cursors continue them',
      () async {
        final file = (await RevFile.db.findById(session, state.fileId))!;
        final seen = <String>[];
        String? cursor;
        do {
          final p = await RevPages.page(
            session,
            binding,
            file,
            RevPageRequest(
              kind: RevPageKind.structure,
              cursor: cursor,
              maxRows: 2,
            ),
          );
          seen.addAll(
            RevPageCodec.decode(
              binding.schema,
              RevCodec.gunzip(p.body.buffer.asUint8List()),
            ).map((r) => r.$2['id']! as String),
          );
          cursor = p.nextCursor;
        } while (cursor != null);
        expect(seen.toSet(), {ids.doc, ids.sheet, ...ids.rows});
      },
    );

    test('when ops commit then the headless model follows them', () async {
      final lease = (await HeadlessFileCache.open(
        session,
        binding,
        item.uuid,
      ))!;
      try {
        await submit([ids.setCell(0, 3, 'live')]);
        await lease.ensureAtLeast(session, state.revision);
        final model = lease.model as MapRowStore;
        expect(model.row('rl_cell', ids.cell(0, 3))!['content'], 'live');
        expect(lease.revision, state.revision);
      } finally {
        lease.release();
      }
    });

    test(
      'when ops commit then hooks see each op once, also after a failure',
      () async {
        binding.hook.seen.clear();
        final c1 = await submit([ids.setCell(1, 3, 'h1')]);
        await RevHooks.drainNow(
          session.serverpod,
          binding,
          state.fileId,
          session: session,
        );
        binding.hook.fail = true;
        final c2 = await submit([ids.setCell(1, 3, 'h2')]);
        await RevHooks.drainNow(
          session.serverpod,
          binding,
          state.fileId,
          session: session,
        );
        expect(binding.hook.seen, isNot(contains(c2.revision)));
        final hs = await RevHookState.db.findFirstRow(
          session,
          where: (t) => t.fileId.equals(state.fileId),
        );
        expect(hs!.attempts, 1);
        await RevHooks.drainNow(
          session.serverpod,
          binding,
          state.fileId,
          session: session,
        );
        expect(
          binding.hook.seen,
          containsAllInOrder([c1.revision, c2.revision]),
        );
        expect(binding.hook.seen.where((r) => r == c2.revision), hasLength(1));
      },
    );

    test('when the file is purged then its rows and log are gone', () async {
      await submit([ids.setCell(0, 0, 'gone')]);
      final fileId = state.fileId;
      await RevLogService.purgeFile(session, binding, item.uuid);
      expect(await row('rl_cell', ids.cell(0, 0)), isNull);
      expect(await row('rl_doc', ids.doc), isNull);
      expect(await RevFile.db.findById(session, fileId), isNull);
      expect(
        await RevOp.db.count(session, where: (t) => t.fileId.equals(fileId)),
        0,
      );
    });
  });
}
