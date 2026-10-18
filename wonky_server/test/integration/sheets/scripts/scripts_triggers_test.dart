@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/common/errors.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/scripts/script_jobs.dart';
import 'package:wonky_server/src/sheets/scripts/script_service.dart';
import 'package:wonky_server/src/sheets/scripts/script_authorizations.dart';
import 'package:wonky_server/src/sheets/scripts/script_triggers.dart';
import 'package:wonky_server/src/sheets/scripts/url_fetch_proxy.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_server_writes.dart';
import 'package:wonky_sheets_core/model.dart'
    show ChangeSummary, GridRange, ChangeKinds, RowChange, SheetsTables;
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sync_models/ids.dart' show SheetsIds;
import 'package:wonky_sheets_script/wonky_sheets_script.dart'
    show EditEventData;

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/sheets_rev_device.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'script_support.dart';

const _source = r'''
import 'package:wonky/wonky.dart';

void install() {
  ScriptApp.newTrigger('stamp').timeBased().everyMinutes(5).create();
}

void installEdit() {
  ScriptApp.newTrigger('markEdit').forSpreadsheet().onEdit().create();
}

void stamp(TimeEvent e) {
  SpreadsheetApp.active.sheetByName('Data')!.appendRow(['tick', e.triggerUid]);
}

void markEdit(EditEvent e) {
  e.range.offset(0, 4).value = 'edited ${e.range.a1Notation}';
}

Object? fetchIt(Object? url) => UrlFetchApp.fetch(url as String).contentText;

void say() {
  Logger.log('a');
  Logger.log('b');
}

void installBoom() {
  ScriptApp.newTrigger('boom').forSpreadsheet().onEdit().create();
}

void boom(EditEvent e) {
  throw StateError('kaput');
}
''';

void main() {
  withWonkyServerpod('Given a script with installable triggers', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late String ss;
    late DriveItem item;

    setUpAll(enableScripting);
    tearDownAll(disableScripting);

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Log',
        sheets: {
          'Data': [
            ['Item', 'Amount'],
            ['Rent', 1000],
          ],
        },
      );
      await mcp.call('sheets.update_script_file', {
        'spreadsheet': ss,
        'name': 'main.dart',
        'source': _source,
        'create_if_missing': true,
      });
      item = (await DriveItem.db.findFirstRow(
        anna.session,
        where: (t) => t.uuid.equals(uuidOf(ss)),
      ))!;
    });
    tearDown(HeadlessWorkbookProvider.clear);

    // The build needs both scopes (triggers and fetches); a run needs a
    // grant covering all of them (09 §11.2).
    Future<void> authorize(TestUser u, List<String> scopes) =>
        ScriptAuthorizations.authorize(u.session, u.actor, uuidOf(ss), [
          ...scopes,
          'script.triggers',
          'external_request',
        ]);

    test('when installing a trigger without the scope then it fails', () async {
      final r = await mcp.error('sheets.run_function', {
        'spreadsheet': ss,
        'function': 'install',
      });
      expect(r['code'], 'authorization_required');
    });

    test(
      'when a time-driven trigger is due then the scheduler runs it as the installer',
      () async {
        await authorize(anna, ['script.triggers']);
        final r = await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'install',
        });
        expect(r['status'], 'completed', reason: '$r');
        final project = await ScriptService.project(
          anna.session,
          item.contentRef!,
        );
        final triggers = await ScriptTrigger.db.find(
          anna.session,
          where: (t) => t.projectId.equals(project!.id),
        );
        expect(triggers.single.functionName, 'stamp');

        final session = anna.session;
        await ScriptTriggerService.tick(session);
        final scheduled = (await _states(session, item)).single;
        expect(scheduled.nextRunAt, isNotNull);
        // Make it due now (moving the clock forward would upset the sync
        // engine's hybrid logical clock).
        final state = await _makeDue(session, scheduled);
        final runs = await ScriptTriggerService.tick(session);
        expect(runs, 1);
        expect(await SheetsFixtures.read(mcp, ss, 'Data!A3'), [
          ['tick'],
        ]);
        final ex = await ScriptExecution.db.find(
          session,
          where: (t) =>
              t.kind.equals(ScriptExecutionKind.timeDriven) &
              t.spreadsheetUuid.equals(item.contentRef!),
        );
        expect(ex.single.status, ScriptExecutionStatus.completed);
        final after = (await _states(session, item)).single;
        expect(after.lastStatus, ScriptExecutionStatus.completed);
        expect(after.nextRunAt!.isAfter(state.nextRunAt!), isTrue);
      },
    );

    test(
      'when the installer loses edit access then the trigger is disabled',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        await SheetsFixtures.share(mcp, ss, bo.email, 'editor');
        await authorize(bo, ['script.triggers']);
        final boMcp = await McpHarness.forUser(bo);
        await boMcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'install',
        });
        await SheetsFixtures.share(mcp, ss, bo.email, 'viewer');
        final session = anna.session;
        await ScriptTriggerService.tick(session);
        await _makeDue(session, (await _states(session, item)).single);
        await ScriptTriggerService.tick(session);
        final after = (await _states(session, item)).single;
        expect(after.disabledReason, contains('no longer has edit access'));
      },
    );

    test(
      'when a user edit syncs then the installable onEdit trigger runs',
      () async {
        await authorize(anna, ['script.triggers']);
        await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'installEdit',
        });
        final model = (await HeadlessWorkbookProvider.open(
          anna.session,
          item.contentRef!,
        )).model;
        final sheet = model.sheetByName('Data')!;
        final summary = ChangeSummary()
          ..kinds.add(ChangeKinds.values)
          ..addRange(
            GridRange(
              sheetId: sheet.id,
              r1: sheet.rows.idAt(1),
              r2: sheet.rows.idAt(1),
              c1: sheet.columns.idAt(1),
              c2: sheet.columns.idAt(1),
            ).toJson(),
          );
        final n = await ScriptTriggerService.fireForChange(
          anna.session,
          item,
          summaryJson: summary.encode(),
          actorKind: ActorKind.user,
          offline: false,
        );
        expect(n, 1);
        expect(await SheetsFixtures.read(mcp, ss, 'Data!F2'), [
          ['edited B2'],
        ]);
      },
    );

    test(
      'when a user types through RevLog then the scripts hook runs the '
      'onEdit trigger',
      () async {
        await authorize(anna, ['script.triggers']);
        await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'installEdit',
        });
        final device = await SheetsRevDevice.open(anna, item.contentRef!);
        try {
          await device.setCell(1, 1, '1200');
        } finally {
          await device.close();
        }
        await drainHooks(anna.session, item.contentRef!);
        expect(await SheetsFixtures.read(mcp, ss, 'Data!F2'), [
          ['edited B2'],
        ]);
        final ex = await ScriptExecution.db.find(
          anna.session,
          where: (t) =>
              t.kind.equals(ScriptExecutionKind.installableOnEdit) &
              t.spreadsheetUuid.equals(item.contentRef!),
        );
        expect(ex.single.status, ScriptExecutionStatus.completed);
      },
    );

    test(
      'when an agent edit syncs then the onEdit trigger does not run by default',
      () async {
        await authorize(anna, ['script.triggers']);
        await mcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'installEdit',
        });
        final n = await ScriptTriggerService.fireForChange(
          anna.session,
          item,
          summaryJson: (ChangeSummary()..kinds.add(ChangeKinds.values))
              .encode(),
          actorKind: ActorKind.mcp,
          offline: false,
        );
        expect(n, 0);
      },
    );

    /// The summary of a user edit of Data!B2.
    Future<String> userEdit() async {
      final model = (await HeadlessWorkbookProvider.open(
        anna.session,
        item.contentRef!,
      )).model;
      final sheet = model.sheetByName('Data')!;
      final summary = ChangeSummary()
        ..kinds.add(ChangeKinds.values)
        ..addRange(
          GridRange(
            sheetId: sheet.id,
            r1: sheet.rows.idAt(1),
            r2: sheet.rows.idAt(1),
            c1: sheet.columns.idAt(1),
            c2: sheet.columns.idAt(1),
          ).toJson(),
        );
      return summary.encode();
    }

    Future<ScriptTrigger> installed(String fn) async {
      await authorize(anna, ['script.triggers']);
      await mcp.call('sheets.run_function', {
        'spreadsheet': ss,
        'function': fn,
      });
      final project = await ScriptService.project(
        anna.session,
        item.contentRef!,
      );
      return (await ScriptTrigger.db.find(
        anna.session,
        where: (t) => t.projectId.equals(project!.id),
      )).single;
    }

    test(
      'when a trigger of an editor writes into a range protected by the '
      'owner then the run fails and the cell is unchanged',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        await SheetsFixtures.share(mcp, ss, bo.email, 'editor');
        // Anna protects column F (where markEdit writes) for herself only.
        final protect = await mcp.call('sheets.protect_range', {
          'spreadsheet': ss,
          'range': 'Data!F1:F20',
          'description': 'Owner only',
        });
        expect(protect, isNotNull);
        await authorize(bo, ['script.triggers']);
        final boMcp = await McpHarness.forUser(bo);
        await boMcp.call('sheets.run_function', {
          'spreadsheet': ss,
          'function': 'installEdit',
        });
        final n = await ScriptTriggerService.fireForChange(
          anna.session,
          item,
          summaryJson: await userEdit(),
          actorKind: ActorKind.user,
          offline: false,
        );
        expect(n, 1);
        expect(
          '${await SheetsFixtures.read(mcp, ss, 'Data!F2')}',
          isNot(
            contains('edited'),
          ),
        );
        final ex = await ScriptExecution.db.find(
          anna.session,
          where: (t) =>
              t.kind.equals(ScriptExecutionKind.installableOnEdit) &
              t.spreadsheetUuid.equals(item.contentRef!),
        );
        expect(ex.single.runAsUserId, bo.id);
        expect(ex.single.status, ScriptExecutionStatus.failed);
        expect(ex.single.errorMessage, contains('protected'));

        // The sequencer enforces it too: script ops of the run-as user are
        // checked (RevLog spec 05 §3.5), only system ops are exempt.
        final model = (await HeadlessWorkbookProvider.open(
          anna.session,
          item.contentRef!,
        )).model;
        final sheet = model.sheetByName('Data')!;
        final r = sheet.rows.idAt(1);
        final c = sheet.columns.idAt(5);
        await expectLater(
          SheetsServerWrites.apply(
            bo.session,
            actor: bo.actor.copyWith(kind: ActorKind.script),
            fileUuid: item.contentRef!,
            changes: [
              RowChange.insert(
                SheetsTables.cell,
                SheetsIds.cellId(sheet.id, r, c),
                {
                  'sheetId': sheet.id,
                  'rowId': r,
                  'columnId': c,
                  'content': 's:sneaky',
                },
              ),
            ],
            label: 'Script: markEdit',
          ),
          throwsA(
            isA<WonkyException>().having(
              Errors.isProtectedRange,
              'protected range',
              isTrue,
            ),
          ),
        );
      },
    );

    test('when run live on the server then log lines stream before the '
        'result', () async {
      await authorize(anna, ['script.triggers']);
      final events = await endpoints.script
          .runLive(anna.endpointSession, uuidOf(ss), 'say', null)
          .map((e) => jsonDecode(e) as Map)
          .toList();
      expect(
        [
          for (final e in events)
            if (e['log'] != null) (e['log'] as Map)['msg'],
        ],
        ['a', 'b'],
      );
      expect((events.last['result'] as Map)['status'], 'completed');
    });

    group('and the job queue (09 §8.5)', () {
      test(
        'when more than 100 runs queue for a trigger then the overflow is '
        'coalesced into the newest job with the bounding range',
        () async {
          final t = await installed('installEdit');
          final session = anna.session;
          for (var i = 0; i < 102; i++) {
            await ScriptJobQueue.enqueue(
              session,
              item: item,
              trigger: t,
              kind: ScriptExecutionKind.installableOnEdit,
              event: EditEventData(
                sheetId: 's1',
                range: GridRect(i, 1, i, 1),
                triggerUid: t.id.uuid,
              ),
            );
          }
          final jobs = await ScriptJob.db.find(
            session,
            where: (j) => j.triggerId.equals(t.id),
            orderBy: (j) => j.id,
          );
          expect(jobs, hasLength(ScriptJobQueue.perTriggerCap));
          expect(jobs.last.coalesced, 2);
          final e =
              ScriptJobEvents.decode(jobs.last.payloadJson) as EditEventData;
          expect(e.coalesced, isTrue);
          expect(e.range, const GridRect(99, 1, 101, 1));
          await ScriptJob.db.deleteWhere(
            session,
            where: (j) => j.triggerId.equals(t.id),
          );
        },
      );

      test(
        'when a run of the trigger is in progress then the next waits, and '
        'an expired lease is queued again',
        () async {
          final t = await installed('installEdit');
          final session = anna.session;
          final running = await ScriptJob.db.insertRow(
            session,
            ScriptJob(
              kind: ScriptExecutionKind.installableOnEdit,
              spreadsheetUuid: item.contentRef!,
              itemUuid: item.uuid,
              triggerId: t.id,
              runAsUserId: anna.id,
              functionName: 'markEdit',
              payloadJson: '{"type":"open"}',
              status: ScriptExecutionStatus.running,
              enqueuedAt: clock.now().toUtc(),
              leaseOwner: 'elsewhere',
              leaseUntil: clock.now().toUtc().add(const Duration(hours: 1)),
              attempts: 1,
            ),
          );
          await ScriptJobQueue.enqueue(
            session,
            item: item,
            trigger: t,
            kind: ScriptExecutionKind.installableOnChange,
            event: const EditEventData(
              sheetId: 'x',
              range: GridRect(0, 0, 0, 0),
            ),
          );
          expect(await ScriptJobQueue.pump(session), 0);

          await ScriptJob.db.updateRow(
            session,
            running.copyWith(
              leaseUntil: clock.now().toUtc().subtract(
                const Duration(minutes: 1),
              ),
            ),
          );
          expect(await ScriptJobQueue.recoverStale(session), 1);
          final again = await ScriptJob.db.findById(session, running.id!);
          expect(again!.status, ScriptExecutionStatus.queued);
          await ScriptJob.db.deleteWhere(
            session,
            where: (j) => j.triggerId.equals(t.id),
          );
        },
      );

      test(
        'when the installer turned scripts off then the trigger pauses',
        () async {
          await installed('installEdit');
          final prefs = await UserPreferences.db.findFirstRow(
            anna.session,
            where: (p) => p.userId.equals(anna.id),
          );
          final off = '{"scriptsEnabled": false}';
          if (prefs == null) {
            await UserPreferences.db.insertRow(
              anna.session,
              UserPreferences(userId: anna.id, sheetsDefaults: off),
            );
          } else {
            await UserPreferences.db.updateRow(
              anna.session,
              prefs.copyWith(sheetsDefaults: off),
            );
          }
          final n = await ScriptTriggerService.fireForChange(
            anna.session,
            item,
            summaryJson: await userEdit(),
            actorKind: ActorKind.user,
            offline: false,
          );
          expect(n, 1);
          final f2 = await SheetsFixtures.read(mcp, ss, 'Data!F2');
          expect('$f2', isNot(contains('edited')));
          final state = (await _states(anna.session, item)).single;
          expect(state.consecutiveFailures, 0);
          expect(state.disabledReason, isNull);
        },
      );

      test(
        'when a trigger fails then the installer gets a script failure '
        'notification once a day',
        () async {
          await installed('installBoom');
          for (var i = 0; i < 2; i++) {
            await ScriptTriggerService.fireForChange(
              anna.session,
              item,
              summaryJson: await userEdit(),
              actorKind: ActorKind.user,
              offline: false,
            );
          }
          final notes = await UserNotification.db.find(
            anna.session,
            where: (n) =>
                n.userId.equals(anna.id) &
                n.kind.equals(NotificationKind.scriptFailure),
          );
          expect(notes, hasLength(1));
          expect(notes.single.payload, contains('kaput'));
          final state = (await _states(anna.session, item)).single;
          expect(state.consecutiveFailures, 2);
          expect(state.lastNotifiedAt, isNotNull);
        },
      );
    });

    group('and a URL to fetch', () {
      late HttpServer server;
      setUp(() async {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((req) async {
          req.response.write('hello from ${req.uri.path}');
          await req.response.close();
        });
        ScriptService.proxyOverride = UrlFetchProxy(
          allowHttp: true,
          lookup: (_) async => [InternetAddress.loopbackIPv4],
          allowedAddressesForTests: {'127.0.0.1'},
          ports: {server.port},
        );
      });
      tearDown(() async {
        ScriptService.proxyOverride = null;
        await server.close(force: true);
      });

      test(
        'when the user authorized network access then server runs can fetch',
        () async {
          await authorize(anna, ['external_request']);
          final r = await mcp.call('sheets.run_function', {
            'spreadsheet': ss,
            'function': 'fetchIt',
            'args': ['http://api.test:${server.port}/rates'],
          });
          expect(r['result'], 'hello from /rates');
          final usage = await ScriptAuthorizations.usage(anna.session, anna.id);
          expect(usage.urlFetchCalls, 1);
        },
      );

      test(
        'when a client fetches through the endpoint then it needs the grant',
        () async {
          final request = '{"url": "http://api.test:${server.port}/x"}';
          await expectLater(
            endpoints.script.urlFetch(
              anna.endpointSession,
              uuidOf(ss),
              request,
              customFunction: false,
            ),
            throwsA(isA<WonkyException>()),
          );
          await endpoints.script.authorize(anna.endpointSession, uuidOf(ss), [
            'external_request',
          ]);
          final r = await endpoints.script.urlFetch(
            anna.endpointSession,
            uuidOf(ss),
            request,
            customFunction: false,
          );
          expect(r.statusCode, 200);
          expect(r.contentText, 'hello from /x');
        },
      );

      test(
        'when the URL points to a private address then the fetch is blocked',
        () async {
          ScriptService.proxyOverride = UrlFetchProxy(
            lookup: (_) async => [InternetAddress('10.0.0.5')],
          );
          await authorize(anna, ['external_request']);
          final r = await mcp.call('sheets.run_function', {
            'spreadsheet': ss,
            'function': 'fetchIt',
            'args': ['https://intranet.example.com/'],
          });
          expect((r['error'] as Map)['type'], 'UrlFetchException');
          expect((r['error'] as Map)['message'], contains('Blocked'));
        },
      );
    });

    test(
      'when the user reports client executions then they appear in the log',
      () async {
        final n = await endpoints.script.reportExecutions(
          anna.endpointSession,
          uuidOf(ss),
          [
            ScriptExecution(
              uuid: const Uuid().v7obj(),
              spreadsheetUuid: uuidOf(ss),
              functionName: 'menuThing',
              kind: ScriptExecutionKind.menu,
              userId: 0,
              runAsUserId: 0,
              runtime: ScriptRuntimeKind.clientWeb,
              status: ScriptExecutionStatus.completed,
              buildSourceHash: 'h',
              startedAt: clock.now().toUtc(),
              durationMs: 120,
              logs: '',
              cellsRead: 1,
              cellsWritten: 2,
              fetchCalls: 0,
            ),
          ],
        );
        expect(n, 1);
        final list = await endpoints.script.executions(
          anna.endpointSession,
          uuidOf(ss),
          limit: 50,
        );
        expect(list.single.functionName, 'menuThing');
        expect(list.single.userId, anna.id);
      },
    );
  });
}

Future<ScriptTriggerState> _makeDue(Session session, ScriptTriggerState s) =>
    ScriptTriggerState.db.updateRow(
      session,
      s.copyWith(
        nextRunAt: clock.now().toUtc().subtract(const Duration(seconds: 5)),
      ),
    );

Future<List<ScriptTriggerState>> _states(Session session, DriveItem item) =>
    ScriptTriggerState.db.find(
      session,
      where: (t) => t.spreadsheetUuid.equals(item.contentRef!),
    );
