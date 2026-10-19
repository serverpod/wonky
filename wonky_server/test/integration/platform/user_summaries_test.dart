@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/users/user_service.dart';

import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// User summaries (CQ-32): avatars of a batch are looked up in one query
/// and cached in a bounded map.
void main() {
  withWonkyServerpod('Given users with avatars', (sessionBuilder, endpoints) {
    Future<UuidValue> avatar(TestUser user) async {
      final session = user.session;
      final uuid = const Uuid().v7obj();
      final path = 'files/avatar/${uuid.uuid}/a.png';
      await session.storage.storeFile(
        storageId: 'public',
        path: path,
        byteData: ByteData.sublistView(Uint8List.fromList([1, 2, 3])),
      );
      final now = clock.now().toUtc();
      await StoredFile.db.insertRow(
        session,
        StoredFile(
          fileUuid: uuid,
          ownerId: user.id,
          kind: StoredFileKind.avatar,
          storageId: 'public',
          path: path,
          fileName: 'a.png',
          mimeType: 'image/png',
          sizeBytes: 3,
          status: StoredFileStatus.ready,
          createdAt: now,
          completedAt: now,
        ),
      );
      await UserService.setAvatar(session, user.actor, uuid);
      return uuid;
    }

    test('when summaries of several users are built then each has its '
        'avatar URL', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final ben = await TestUsers.create(sessionBuilder, name: 'Ben');
      final cat = await TestUsers.create(sessionBuilder, name: 'Cat');
      await avatar(anna);
      await avatar(ben);

      final summaries = await UserService.summaries(anna.session, [
        anna.id,
        ben.id,
        cat.id,
      ]);

      expect(summaries[anna.id]!.avatarUrl, isNotNull);
      expect(summaries[ben.id]!.avatarUrl, isNotNull);
      expect(
        summaries[anna.id]!.avatarUrl,
        isNot(summaries[ben.id]!.avatarUrl),
      );
      expect(summaries[cat.id]!.avatarUrl, isNull);
    });
  });
}
