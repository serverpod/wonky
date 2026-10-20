@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/protocol.dart' as sp show FutureCallEntry;
import 'package:test/test.dart';
import 'package:wonky_server/server.dart'
    show recurringJobIds, scheduleMaintenanceJobs, scheduleRecurringJobs;
import 'package:wonky_server/src/generated/future_calls.dart';

import '../support/wonky_serverpod.dart';

/// Every instance schedules the recurring jobs at start (specs/13 §4).
void main() {
  withWonkyServerpod('Given several instances starting', (
    sessionBuilder,
    endpoints,
  ) {
    final jobs = recurringJobIds.toSet();

    /// Upcoming runs per job identifier.
    Future<Map<String, int>> upcoming() async {
      final entries = await sp.FutureCallEntry.db.find(
        sessionBuilder.build(),
        where: (t) => t.identifier.inSet(jobs),
      );
      final now = clock.now().toUtc();
      return {
        for (final id in jobs)
          id: entries
              .where((e) => e.identifier == id && e.time.isAfter(now))
              .length,
      };
    }

    test('when listing the recurring jobs then the maintenance, RevLog, '
        'script, storage, board and publication jobs are there', () {
      expect(
        jobs,
        containsAll([
          'wonky.captureVersions',
          'wonky.daily',
          'wonky.revlogSweep',
          'wonky.scriptsTick',
          'wonky.storageReconcile',
          'wonky.boardSweep',
          'wonky.publicationSweep',
        ]),
      );
    });

    test(
      'when they schedule the maintenance jobs at the same time then each '
      'job is scheduled once',
      () async {
        final pod = sessionBuilder.build().serverpod;

        await Future.wait([
          scheduleMaintenanceJobs(pod),
          scheduleMaintenanceJobs(pod),
          scheduleMaintenanceJobs(pod),
        ]);

        expect(await upcoming(), {for (final id in jobs) id: 1});
      },
    );

    test('when every job is already scheduled then scheduling again changes '
        'nothing', () async {
      final session = sessionBuilder.build();
      await scheduleMaintenanceJobs(session.serverpod);

      final again = await scheduleRecurringJobs(
        session,
        session.serverpod.futureCalls,
      );

      expect(again, isEmpty);
      expect(await upcoming(), {for (final id in jobs) id: 1});
    });

    test(
      'when a job was scheduled twice then the next start repairs it',
      () async {
        final pod = sessionBuilder.build().serverpod;
        await scheduleMaintenanceJobs(pod);
        await pod.futureCalls
            .callRecurring(identifier: 'wonky.daily')
            .cron('17 3 * * *')
            .maintenance
            .daily();

        final session = sessionBuilder.build();
        final repaired = await scheduleRecurringJobs(
          session,
          session.serverpod.futureCalls,
        );

        expect(repaired, ['wonky.daily']);
        expect(await upcoming(), {for (final id in jobs) id: 1});
      },
    );

    test('when a job is missing then only that job is scheduled', () async {
      final session = sessionBuilder.build();
      await scheduleMaintenanceJobs(session.serverpod);
      await session.serverpod.futureCalls.cancel('wonky.scriptsPrune');

      final scheduled = await scheduleRecurringJobs(
        session,
        session.serverpod.futureCalls,
      );

      expect(scheduled, ['wonky.scriptsPrune']);
      expect(await upcoming(), {for (final id in jobs) id: 1});
    });
  });
}
