@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given Bo added a shortcut to Anna\'s shared document', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser bo;
    late DriveItemView doc;
    setUp(() async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna, name: 'Plan');
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
    });

    Future<List<String>> names(DriveItemView? folder) async {
      final page = await endpoints.drive.list(
        bo.endpointSession,
        folder?.uuid,
        DriveListFilter(),
        DriveSort(),
        null,
        100,
      );
      return [for (final i in page.items) i.name];
    }

    // Regression: the shortcut query built an untyped id set
    // (`Set<int?>`), which threw a TypeError in `inSet`.
    test('when Bo lists My Drive then the shortcut is listed', () async {
      await endpoints.drive.addShortcut(bo.endpointSession, doc.uuid, null);

      expect(await names(null), contains('Plan'));
    });

    test('when Bo lists his folder then the shortcut is listed', () async {
      final folder = await TestDrive.folder(endpoints, bo, name: 'Mine');
      await endpoints.drive.addShortcut(
        bo.endpointSession,
        doc.uuid,
        folder.uuid,
      );

      expect(await names(folder), contains('Plan'));
    });
  });
}
