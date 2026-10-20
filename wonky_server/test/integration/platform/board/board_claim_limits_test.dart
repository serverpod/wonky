@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/board_sweep.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/board/board_harness.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

Matcher _code(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// Claim limits and claim blocks (specs/16 §8.1, §8.4).
void main() {
  withWonkyServerpod('Given four published tasks', (sessionBuilder, endpoints) {
    late BoardHarness h;
    late TestUser anna;
    late TestUser bo;
    late TestUser admin;
    late List<BoardTaskView> tasks;
    setUp(() async {
      h = BoardHarness.install();
      h.ai.jev = false;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      admin = await BoardHarness.admin(sessionBuilder);
      tasks = [
        for (var i = 0; i < 4; i++)
          await BoardHarness.publishedTask(endpoints, admin, [
            (await BoardHarness.post(endpoints, anna)).number,
          ], title: 'Task number $i'),
      ];
    });
    tearDown(() => h.uninstall());

    Future<BoardTaskView> claim(TestUser who, int i) =>
        endpoints.board.claimTask(who.endpointSession, tasks[i].number);

    test('when claiming three tasks then the server accepts them and '
        'refuses a fourth', () async {
      for (var i = 0; i < 3; i++) {
        expect((await claim(bo, i)).claimedBy?.id, bo.id);
      }

      await expectLater(claim(bo, 3), _code(WonkyErrorCode.limitExceeded));
      final me = await endpoints.board.me(bo.endpointSession);
      expect(me.activeClaims, hasLength(3));
      expect(me.maxActiveClaims, 3);
      expect(me.claimBlockedUntil, isNull);
    });

    test('when three claims expire then the claimant cannot claim for two '
        'weeks', () async {
      final start = clock.now().toUtc();
      await withClock(Clock.fixed(start), () async {
        for (var i = 0; i < 3; i++) {
          await claim(bo, i);
        }
      });
      final expiredAt = start.add(const Duration(hours: 49));
      await withClock(
        Clock.fixed(expiredAt),
        () => BoardSweep.run(sessionBuilder.build()),
      );

      await withClock(
        Clock.fixed(expiredAt.add(const Duration(hours: 1))),
        () async {
          await expectLater(claim(bo, 3), _code(WonkyErrorCode.forbidden));
          final me = await endpoints.board.me(bo.endpointSession);
          expect(me.claimBlockedUntil, expiredAt.add(const Duration(days: 14)));
          expect(me.claimBlockedReason, contains('3 of your claims expired'));
          // Others are not affected.
          expect((await claim(anna, 3)).claimedBy?.id, anna.id);
        },
      );
      await withClock(
        Clock.fixed(expiredAt.add(const Duration(days: 14, minutes: 1))),
        () async {
          expect((await claim(bo, 0)).claimedBy?.id, bo.id);
          final me = await endpoints.board.me(bo.endpointSession);
          expect(me.claimBlockedUntil, isNull);
        },
      );
    });

    test('when two claims expire or a claim is released then claiming '
        'still works', () async {
      final start = clock.now().toUtc();
      await withClock(Clock.fixed(start), () async {
        await claim(bo, 0);
        await claim(bo, 1);
        await claim(bo, 2);
        await endpoints.board.releaseTask(bo.endpointSession, tasks[2].number);
      });
      final later = start.add(const Duration(hours: 49));
      await withClock(
        Clock.fixed(later),
        () => BoardSweep.run(sessionBuilder.build()),
      );

      await withClock(
        Clock.fixed(later.add(const Duration(hours: 1))),
        () async => expect((await claim(bo, 3)).claimedBy?.id, bo.id),
      );
    });

    group('when a moderator removes issues by the claimant', () {
      Future<BoardPostView> removed(TestUser author) async {
        final p = await BoardHarness.post(endpoints, author);
        return endpoints.board.moderatePost(
          admin.endpointSession,
          p.number,
          BoardModerationAction.remove,
          'spam',
        );
      }

      test('then one removed issue does not block claiming', () async {
        await removed(bo);

        expect((await claim(bo, 0)).claimedBy?.id, bo.id);
      });

      test('then two removed issues block claiming for two weeks, and '
          'restoring one lifts the block', () async {
        final start = clock.now().toUtc();
        late BoardPostView second;
        await withClock(Clock.fixed(start), () async {
          await removed(bo);
          second = await removed(bo);
        });

        await expectLater(claim(bo, 0), _code(WonkyErrorCode.forbidden));
        final me = await endpoints.board.me(bo.endpointSession);
        expect(
          me.claimBlockedUntil!.difference(start),
          const Duration(days: 14),
        );
        expect(me.claimBlockedReason, contains('removed 2 of your issues'));

        await endpoints.board.moderatePost(
          admin.endpointSession,
          second.number,
          BoardModerationAction.restore,
          null,
        );
        expect((await claim(bo, 0)).claimedBy?.id, bo.id);
      });

      test('then the block ends after two weeks', () async {
        final start = clock.now().toUtc();
        await withClock(Clock.fixed(start), () async {
          await removed(bo);
          await removed(bo);
        });

        await withClock(
          Clock.fixed(start.add(const Duration(days: 14, minutes: 1))),
          () async => expect((await claim(bo, 0)).claimedBy?.id, bo.id),
        );
      });
    });
  });
}
