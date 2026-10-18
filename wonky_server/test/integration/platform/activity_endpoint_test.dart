@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/activity/activity_service.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/role_matrix.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a shared document with viewers', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late TestUser cleo;
    late DriveItemView doc;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      cleo = await TestUsers.create(sessionBuilder, name: 'Cleo');
      doc = await TestDrive.document(endpoints, anna, name: 'Plan');
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
      await TestDrive.share(endpoints, doc, anna, cleo, AccessRole.viewer);
    });

    Future<ActivityDashboard> dashboard(TestUser user, {int days = 7}) =>
        endpoints.activity.dashboard(user.endpointSession, doc.uuid, days);

    test(
      'when Bo opens it twice then the owner sees Bo with two views',
      () async {
        await endpoints.drive.markOpened(bo.endpointSession, doc.uuid);
        await endpoints.drive.markOpened(bo.endpointSession, doc.uuid);

        final d = await dashboard(anna);

        final row = d.viewers.singleWhere((v) => v.user.id == bo.id);
        expect(row.views, 2);
        expect(row.role, AccessRole.editor);
        expect(d.viewTrend.last.count, 1);
      },
    );

    test('when a viewer opens the dashboard then trends are shown but no '
        'viewers', () async {
      await endpoints.drive.markOpened(bo.endpointSession, doc.uuid);

      final d = await dashboard(cleo);

      expect(d.canSeeViewers, isFalse);
      expect(d.viewers, isEmpty);
      expect(d.viewTrend, hasLength(7));
      expect(d.viewTrend.last.count, greaterThanOrEqualTo(1));
    });

    test(
      'when Bo turns view history off then Bo is hidden but still counted',
      () async {
        await endpoints.drive.markOpened(bo.endpointSession, doc.uuid);

        final setting = await endpoints.activity.setShowViewHistory(
          bo.endpointSession,
          false,
        );
        final d = await dashboard(anna);

        expect(setting, isFalse);
        expect(d.viewers.where((v) => v.user.id == bo.id), isEmpty);
        expect(d.hiddenViewers, 1);
        expect(d.viewTrend.last.count, 1);
        expect((await dashboard(bo)).showMyViewHistory, isFalse);
      },
    );

    test(
      'when Bo turns view history back on then Bo is listed again',
      () async {
        await endpoints.drive.markOpened(bo.endpointSession, doc.uuid);
        await endpoints.activity.setShowViewHistory(bo.endpointSession, false);

        await endpoints.activity.setShowViewHistory(bo.endpointSession, true);

        expect(
          (await dashboard(anna)).viewers.map((v) => v.user.id),
          contains(bo.id),
        );
        expect(
          await endpoints.activity.showViewHistory(bo.endpointSession),
          isTrue,
        );
      },
    );

    test(
      'when someone opens it through the link then they are not listed',
      () async {
        final dan = await TestUsers.create(sessionBuilder, name: 'Dan');
        await endpoints.sharing.setLink(
          anna.endpointSession,
          doc.uuid,
          AccessRole.viewer,
        );

        await endpoints.drive.markOpened(dan.endpointSession, doc.uuid);
        final d = await dashboard(anna);

        expect(d.viewers.where((v) => v.user.id == dan.id), isEmpty);
        expect(d.viewTrend.last.count, 1);
      },
    );

    test('when views happened on earlier days then the trend has one point '
        'per day', () async {
      final session = sessionBuilder.build();
      final today = ActivityService.dayOf(clock.now().toUtc());
      final item = (await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(doc.uuid),
      ))!;
      await ActivityService.recordView(
        session,
        item.id!,
        bo.id,
        at: today.subtract(const Duration(days: 3, hours: -1)),
      );
      await ActivityService.recordView(
        session,
        item.id!,
        cleo.id,
        at: today.subtract(const Duration(days: 3, hours: -2)),
      );

      final d = await dashboard(anna);

      expect(d.viewTrend.map((p) => p.count).toList(), [0, 0, 0, 2, 0, 0, 0]);
      expect(d.viewTrend.first.day, today.subtract(const Duration(days: 6)));
    });

    test('when comments and replies are added then the comment trend counts '
        'them today', () async {
      final thread = await endpoints.comment.createThread(
        bo.endpointSession,
        const Uuid().v7obj(),
        doc.uuid,
        CommentAnchorKind.document,
        '{"v":1}',
        null,
        'Hello',
        [],
        null,
      );
      await endpoints.comment.reply(
        anna.endpointSession,
        thread.uuid,
        'Hi',
        [],
      );

      final d = await dashboard(anna);

      expect(d.commentTrend.last.count, 2);
      expect(d.commentTrend.first.count, 0);
    });
  });

  withWonkyServerpod('Given the activity dashboard permissions', (
    sessionBuilder,
    endpoints,
  ) {
    forEachRole(
      'Given a document and opening its dashboard',
      endpoints,
      sessionBuilder,
      allowed: {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      },
      act: (caller, c) => endpoints.activity.dashboard(caller, c.item.uuid, 28),
    );
  });
}
