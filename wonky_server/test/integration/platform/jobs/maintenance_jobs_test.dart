@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/jobs/maintenance_future_call.dart';
import 'package:wonky_server/src/platform/sharing/sharing_service.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given the maintenance jobs', (sessionBuilder, endpoints) {
    test('when running the daily chain then every job completes', () async {
      // Regression: `sharing.expiredGrants` threw a TypeError (an Error,
      // not an Exception) that aborted the rest of the chain.
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final old = await AiUsage.db.insertRow(
        anna.session,
        AiUsage(
          userId: anna.id,
          model: 'test',
          feature: 'chat',
          inputTokens: 1,
          outputTokens: 1,
          cacheReadTokens: 0,
          cacheWriteTokens: 0,
          at: clock.now().toUtc().subtract(const Duration(days: 120)),
        ),
      );

      await MaintenanceFutureCall().daily(sessionBuilder.build());

      // The last job of the chain (ai.purgeUsage) ran.
      expect(await AiUsage.db.findById(anna.session, old.id!), isNull);
    });
  });

  withWonkyServerpod('Given more expired grants than one batch', (
    sessionBuilder,
    endpoints,
  ) {
    test('when the expired-grants job runs then all of them are removed and '
        'the access ends', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final guests = [
        for (var i = 0; i < 5; i++)
          await TestUsers.create(sessionBuilder, name: 'Guest $i'),
      ];
      final doc = await TestDrive.document(endpoints, anna);
      for (final g in guests) {
        await TestDrive.share(endpoints, doc, anna, g, AccessRole.viewer);
      }
      final item = await DriveItem.db.findFirstRow(
        anna.session,
        where: (t) => t.uuid.equals(doc.uuid),
      );
      await DriveItemPermission.db.updateWhere(
        anna.session,
        columnValues: (t) => [
          t.expiresAt(
            clock.now().toUtc().subtract(const Duration(hours: 1)),
          ),
        ],
        where: (t) => t.itemId.equals(item!.id!),
      );

      final removed = await SharingService.removeExpiredGrants(
        sessionBuilder.build(),
        batchSize: 2,
      );

      expect(removed, 5);
      expect(
        await DriveItemPermission.db.count(
          anna.session,
          where: (t) => t.itemId.equals(item!.id!),
        ),
        0,
      );
    });
  });
}
