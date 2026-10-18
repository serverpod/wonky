@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/slides/revlog/slides_hooks.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;

import '../../support/slides_rev_device.dart';
import '../../support/slides_rev_hooks.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// The Slides app's client-side creation against the real server (Slides
/// 02 §9.3, RevLog spec 04 §5, 08 §2): `drive.registerPresentation`
/// (`createPresentation(fileUuid, initialize: false)`) makes the file a
/// drive item at revision 0, the app's `CreateDeck` rows are the creation
/// op (revision 1), the hooks accept the planner's summary, and a
/// collaborator's device receives every row.
void main() {
  withWonkyServerpod('Given the Slides app creating a deck', (
    sessionBuilder,
    endpoints,
  ) {
    SlidesRevHooks.install();

    test('when the deck is registered and its creation op commits then the '
        'drive item, the hooks and a collaborator device all see the '
        'deck', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final file = UuidValue.fromString(const Uuid().v7());

      final item = await endpoints.drive.registerPresentation(
        anna.endpointSession,
        file,
        null,
        'Roadmap',
      );
      expect(item.uuid, file);
      expect(item.contentRef, file);

      final a = await SlidesRevDevice.open(anna, file);
      addTearDown(a.close);
      final ack = await a.createDeck('Roadmap');
      expect(ack.revision, 1);
      final written = SlidesTables.dependencyOrder
          .map(a.model.count)
          .fold(0, (n, c) => n + c);

      final server = sessionBuilder.build();
      await SlidesRevHooks.drain(server, file);
      expect(await DeckSearchText.ofFile(server, file), contains('Roadmap'));
      final rev = await RevFile.db.findFirstRow(
        server,
        where: (t) => t.fileUuid.equals(file),
      );
      final op = await RevOp.db.findFirstRow(
        server,
        where: (t) => t.fileId.equals(rev!.id!) & t.revision.equals(1),
      );
      expect(op?.changeCount, written);

      await endpoints.sharing.share(
        anna.endpointSession,
        file,
        [bo.email],
        AccessRole.viewer,
        false,
        null,
        null,
      );
      final b = await SlidesRevDevice.open(bo, file);
      addTearDown(b.close);
      expect(b.role, AccessRole.viewer);
      expect(b.title, 'Roadmap');
      expect(
        SlidesTables.dependencyOrder
            .map(b.model.count)
            .fold(0, (n, c) => n + c),
        written,
      );
    });
  });
}
