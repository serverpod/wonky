@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/style_guide_service.dart';
import 'package:wonky_server/src/platform/ai/style_guides/builtin_style_guides.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

StyleGuideInput _input(
  String name, {
  bool share = false,
  UuidValue? uuid,
}) => StyleGuideInput(
  uuid: uuid,
  name: name,
  description: 'For $name',
  markdown: '# $name\n\n- Short sentences.',
  shareWithOrg: share,
);

void main() {
  withWonkyServerpod('Given users of one organization', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser ben;
    late TestUser gmail;

    Future<TestUser> withEmail(String name, String email) async {
      final u = await TestUsers.create(sessionBuilder, name: name);
      await UserProfile.db.updateRow(
        sessionBuilder.build(),
        u.profile.copyWith(email: email),
      );
      return u;
    }

    setUp(() async {
      final n = DateTime.now().microsecondsSinceEpoch;
      anna = await withEmail('Anna', 'anna.$n@acme.dev');
      ben = await withEmail('Ben', 'ben.$n@acme.dev');
      gmail = await withEmail('Gil', 'gil.$n@gmail.com');
    });

    test('when listing then the built-in guides come first', () async {
      final lib = await endpoints.styleGuide.library(
        anna.endpointSession,
        null,
      );

      expect(
        lib.guides.map((g) => g.ref).take(BuiltinStyleGuides.all.length),
        [for (final b in BuiltinStyleGuides.all) b.ref],
      );
      expect(lib.orgKey, 'acme.dev');
      expect(lib.canSetOrgDefault, isTrue);
    });

    test(
      'when a guide is personal then colleagues do not see it, and when it '
      'is shared then they do',
      () async {
        final mine = await endpoints.styleGuide.save(
          anna.endpointSession,
          _input('House'),
        );
        expect(mine.source, StyleGuideService.sourceMine);
        var benLib = await endpoints.styleGuide.library(
          ben.endpointSession,
          null,
        );
        expect(benLib.guides.map((g) => g.ref), isNot(contains(mine.ref)));

        await endpoints.styleGuide.save(
          anna.endpointSession,
          _input(
            'House',
            share: true,
            uuid: StyleGuideService.uuidOf(mine.ref),
          ),
        );
        benLib = await endpoints.styleGuide.library(ben.endpointSession, null);
        final seen = benLib.guides.firstWhere((g) => g.ref == mine.ref);
        expect(seen.source, StyleGuideService.sourceOrganization);
        expect(seen.editable, isFalse);
        expect(seen.ownerName, 'Anna');
      },
    );

    test('when a public-mail user shares a guide then it is refused', () async {
      await expectLater(
        endpoints.styleGuide.save(
          gmail.endpointSession,
          _input('Mine', share: true),
        ),
        throwsA(isA<WonkyException>()),
      );
      final lib = await endpoints.styleGuide.library(
        gmail.endpointSession,
        null,
      );
      expect(lib.orgKey, isNull);
    });

    test('when a colleague edits a guide then it is refused', () async {
      final g = await endpoints.styleGuide.save(
        anna.endpointSession,
        _input('House', share: true),
      );

      await expectLater(
        endpoints.styleGuide.save(
          ben.endpointSession,
          _input('Mine now', uuid: StyleGuideService.uuidOf(g.ref)),
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when a document has no guide then it uses the organization default',
      () async {
        final doc = await TestDrive.document(endpoints, anna, markdown: 'x\n');
        final session = sessionBuilder.build();
        final item = await DriveItem.db.findFirstRow(
          session,
          where: (i) => i.uuid.equals(doc.uuid),
        );

        await endpoints.styleGuide.setOrgDefault(
          ben.endpointSession,
          'builtin:technical',
        );
        final viaOrg = await StyleGuideService.forDocument(
          session,
          anna.id,
          item!.id!,
        );
        final lib = await endpoints.styleGuide.setDocumentStyle(
          anna.endpointSession,
          doc.uuid,
          'builtin:marketing',
        );
        final own = await StyleGuideService.forDocument(
          session,
          anna.id,
          item.id!,
        );

        expect(viaOrg?.ref, 'builtin:technical');
        expect(own?.ref, 'builtin:marketing');
        expect(lib.documentRef, 'builtin:marketing');
        expect(lib.orgDefaultRef, 'builtin:technical');
        expect(lib.effectiveRef, 'builtin:marketing');
      },
    );

    test(
      'when a personal guide is made the organization default then it is '
      'refused',
      () async {
        final g = await endpoints.styleGuide.save(
          anna.endpointSession,
          _input('Private'),
        );

        await expectLater(
          endpoints.styleGuide.setOrgDefault(anna.endpointSession, g.ref),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test(
      "when a viewer sets a document's guide then it is refused, and "
      'collaborators can read the guide through the document',
      () async {
        final doc = await TestDrive.document(endpoints, anna, markdown: 'x\n');
        final g = await endpoints.styleGuide.save(
          anna.endpointSession,
          _input('Anna only'),
        );
        await endpoints.styleGuide.setDocumentStyle(
          anna.endpointSession,
          doc.uuid,
          g.ref,
        );
        final viewer = await TestUsers.create(sessionBuilder, name: 'Vic');
        await TestDrive.share(endpoints, doc, anna, viewer, AccessRole.viewer);

        await expectLater(
          endpoints.styleGuide.setDocumentStyle(
            viewer.endpointSession,
            doc.uuid,
            null,
          ),
          throwsA(isA<WonkyException>()),
        );
        final lib = await endpoints.styleGuide.library(
          viewer.endpointSession,
          doc.uuid,
        );
        expect(lib.canSetDocument, isFalse);
        expect(lib.documentRef, g.ref);
        expect(
          lib.guides.firstWhere((x) => x.ref == g.ref).source,
          StyleGuideService.sourceDocument,
        );
      },
    );

    test(
      'when a deleted guide is saved again with its uuid then it comes back '
      '(undo of delete)',
      () async {
        final g = await endpoints.styleGuide.save(
          anna.endpointSession,
          _input('Temp'),
        );
        final uuid = StyleGuideService.uuidOf(g.ref)!;

        await endpoints.styleGuide.delete(anna.endpointSession, uuid);
        final back = await endpoints.styleGuide.save(
          anna.endpointSession,
          _input('Temp', uuid: uuid),
        );

        expect(back.ref, g.ref);
      },
    );
  });
}
