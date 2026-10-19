@Tags(['integration'])
library;

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/versions/version_service.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../support/role_matrix.dart';
import '../../support/test_doc_client.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given an edited document', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView item;
    late TestDocClient client;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, name: 'History');
      client = await TestDocClient.connect(endpoints, anna, item.contentRef!);
      client.edit(Delta()..insert('First draft'));
      await client.processUntilSynchronized();
    });
    tearDown(() => client.close());

    test(
      'when naming the current version then it is listed as named',
      () async {
        await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'Draft 1',
        );

        final versions = await endpoints.version.list(
          anna.endpointSession,
          item.uuid,
          true,
        );

        expect(versions.map((v) => (v.name, v.kind)), [
          ('Draft 1', VersionKind.named),
        ]);
        expect(versions.single.revision, client.revision);
        expect(versions.single.authors.map((a) => a.id), [anna.id]);
      },
    );

    test(
      'when the editor is idle for 5 minutes then an auto version is captured',
      () async {
        final session = sessionBuilder.build();

        final early = await VersionService.captureDue(session);
        final later = await VersionService.captureDue(
          session,
          now: clock.now().toUtc().add(const Duration(minutes: 6)),
        );
        final versions = await endpoints.version.list(
          anna.endpointSession,
          item.uuid,
          false,
        );

        expect(early, 0);
        expect(later, 1);
        expect(versions.single.kind, VersionKind.auto);
      },
    );

    test(
      'when restoring a version then the content returns and a restore point exists',
      () async {
        final v1 = await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'v1',
        );
        client.edit(
          Delta()
            ..retain(5)
            ..delete(6)
            ..insert(' version'),
        );
        await client.processUntilSynchronized();

        final result = await endpoints.version.restore(
          anna.endpointSession,
          item.uuid,
          v1.id,
        );
        await client.catchUpTo(result.revision!);
        final versions = await endpoints.version.list(
          anna.endpointSession,
          item.uuid,
          false,
        );

        expect(DeltaUtils.text(client.document), 'First draft\n');
        expect(versions.map((v) => v.kind), contains(VersionKind.restorePoint));
        expect(result.restorePoint.name, 'Before restoring "v1"');
      },
    );

    test(
      'when restoring an unnamed version then the restore point has no raw timestamp name',
      () async {
        client.edit(Delta()..insert('Draft '));
        await client.processUntilSynchronized();
        final session = sessionBuilder.build();
        await VersionService.captureDue(
          session,
          now: clock.now().toUtc().add(const Duration(minutes: 6)),
        );
        final auto = (await endpoints.version.list(
          anna.endpointSession,
          item.uuid,
          false,
        )).firstWhere((v) => v.kind == VersionKind.auto);

        final result = await endpoints.version.restore(
          anna.endpointSession,
          item.uuid,
          auto.id,
        );

        expect(result.restorePoint.kind, VersionKind.restorePoint);
        expect(result.restorePoint.name, isNull);
      },
    );

    test(
      'when reading the document at a revision then the content of that revision is returned',
      () async {
        final at1 = client.revision;
        client.edit(Delta()..insert('New '));
        await client.processUntilSynchronized();

        final version = await endpoints.writeHistory.getVersionDocument(
          anna.endpointSession,
          item.contentRef!,
          at1,
        );

        expect(
          DeltaUtils.text(
            Delta.fromJson(jsonDecode(version.deltaJson) as List),
          ),
          'First draft\n',
        );
      },
    );

    test(
      'when diffing two revisions then insertions are attributed to the author',
      () async {
        final from = client.revision;
        client.edit(Delta()..insert('Added '));
        await client.processUntilSynchronized();

        final diff = await endpoints.writeHistory.diff(
          anna.endpointSession,
          item.contentRef!,
          from,
          client.revision,
        );

        expect(diff.exact, isTrue);
        expect(diff.authors.single.userUuid, anna.authUserId);
        expect(diff.authors.single.inserted, 6);
        expect(diff.deltaJson, contains('diff_ins'));
      },
    );

    test(
      'when copying a version then a new document with that content exists',
      () async {
        final v1 = await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'v1',
        );

        final copy = await endpoints.writeHistory.copyVersion(
          anna.endpointSession,
          item.contentRef!,
          v1.id,
          'Copy of v1',
          null,
        );
        final snapshot = await endpoints.document.getSnapshot(
          anna.endpointSession,
          copy.contentRef!,
          null,
        );

        expect(snapshot.deltaJson, contains('First draft'));
      },
    );
  });

  withWonkyServerpod('Given the version permission matrix', (
    sessionBuilder,
    endpoints,
  ) {
    forEachRole(
      'Given a document and listing versions',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      act: (caller, c) => endpoints.version.list(caller, c.item.uuid, false),
    );
  });
}
