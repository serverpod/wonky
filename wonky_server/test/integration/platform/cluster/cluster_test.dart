@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/cluster/cluster.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/users/user_service.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a cluster with Redis', (sessionBuilder, endpoints) {
    setUp(() => Cluster.debugDistributed = true);
    tearDown(() => Cluster.debugDistributed = null);

    test(
      'when another instance deletes an account then the cached profile id '
      'is forgotten here',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final session = sessionBuilder.build();
        final cached = await UserService.profileIdFor(session, anna.authUserId);
        await UserProfile.db.deleteWhere(
          session,
          where: (t) => t.id.equals(cached),
        );

        await session.messages.postMessage(
          Cluster.signalChannel,
          Cluster.build(
            'user.forget',
            authUserId: anna.authUserId,
          ).copyWith(originInstance: 'another-instance'),
        );
        final fresh = await UserService.profileIdFor(session, anna.authUserId);

        expect(fresh, isNot(cached));
      },
    );
  });
}
