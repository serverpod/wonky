@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/role_matrix.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// The permission matrix of the Slides endpoints (specs/15 §6, Slides 11
/// §2; CQ-59): one test per role, unauthenticated included.
void main() {
  withWonkyServerpod('Given the Slides endpoints', (sessionBuilder, endpoints) {
    Future<DriveItemView> deck(TestUser owner) => endpoints.drive
        .createPresentation(owner.endpointSession, null, 'Deck', null);

    const viewers = {
      AccessRole.owner,
      AccessRole.editor,
      AccessRole.commenter,
      AccessRole.viewer,
    };
    const editors = {AccessRole.owner, AccessRole.editor};

    forEachRole(
      'Given a presentation, slidesDoc.info',
      endpoints,
      sessionBuilder,
      allowed: viewers,
      setup: deck,
      act: (caller, c) => endpoints.slidesDoc.info(caller, c.item.contentRef!),
    );

    forEachRole(
      'Given a presentation, slidesThemes.list',
      endpoints,
      sessionBuilder,
      allowed: viewers,
      setup: deck,
      act: (caller, c) => endpoints.slidesThemes.list(caller, c.item.uuid),
    );

    forEachRole(
      'Given a presentation, presentation.findSession',
      endpoints,
      sessionBuilder,
      allowed: viewers,
      setup: deck,
      act: (caller, c) => endpoints.presentation.findSession(
        caller,
        c.item.uuid,
      ),
    );

    forEachRole(
      'Given a named version of a presentation, slidesVersion.changes',
      endpoints,
      sessionBuilder,
      allowed: editors,
      setup: deck,
      act: (caller, c) async {
        final version = await endpoints.version.nameCurrent(
          c.owner.endpointSession,
          c.item.uuid,
          'v1',
        );
        await endpoints.slidesVersion.changes(caller, c.item.uuid, version.id);
      },
    );
  });
}
