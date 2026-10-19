@Tags(['integration'])
library;

import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/platform/revlog/rev_legacy_files.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_connection.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_service.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'support/test_rev_binding.dart';

void main() {
  withWonkyServerpod('Given files from before RevLog', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser ben;

    setUpAll(() async {
      await createTestTables(sessionBuilder.build());
      RevHooks.debounce = const Duration(hours: 1);
    });
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
    });
    tearDown(RevHooks.idle);

    // A drive item without a rev_file, as the RevLog migration left them.
    Future<DriveItem> legacy({UuidValue? contentRef}) => DriveItem.db.insertRow(
      sessionBuilder.build(),
      DriveItem(
        kind: DriveItemKind.spreadsheet,
        name: 'Old budget',
        ownerId: anna.id,
        contentRef: contentRef,
        createdAt: clock.now().toUtc(),
        createdById: anna.id,
        modifiedAt: clock.now().toUtc(),
      ),
    );

    Future<bool> exists(DriveItem item) async =>
        await DriveItem.db.findById(sessionBuilder.build(), item.id!) != null;

    Future<bool> remove(TestUser user, UuidValue fileUuid) =>
        RevLegacyFiles.removeIfLegacy(
          user.session,
          TestRevBinding.instance,
          user.actor,
          fileUuid,
        );

    test(
      'when its owner opens one then it is rejected as not found and removed',
      () async {
        final item = await legacy();
        final input = StreamController<RevClientMessage>();
        final messages = StreamQueue(
          RevLogConnection.open(
            anna.session,
            TestRevBinding.instance,
            anna.actor,
            item.uuid,
            0,
            'tab-anna',
            input.stream,
          ),
        );
        final m = await messages.next.timeout(const Duration(seconds: 10));
        // Rejected before it listens to the input: closing it never completes.
        unawaited(input.close());
        await messages.cancel(immediate: true);

        expect(m, isA<RevRejected>());
        expect((m as RevRejected).code, RevRejectCode.notFound);
        expect(await exists(item), isFalse);
      },
    );

    test(
      'when one with a content ref is opened then it is removed',
      () async {
        final file = UuidValue.fromString(const Uuid().v7());
        final item = await legacy(contentRef: file);

        expect(await remove(anna, file), isTrue);
        expect(await exists(item), isFalse);
      },
    );

    test(
      'when someone without access opens one then it is kept',
      () async {
        final item = await legacy();

        expect(await remove(ben, item.uuid), isFalse);
        expect(await exists(item), isTrue);
      },
    );

    test('when a RevLog file is opened then it is kept', () async {
      final session = sessionBuilder.build();
      final item = await testItem(session, anna, 'Plan');
      await RevLogService.createFile(
        session,
        binding: TestRevBinding.instance,
        item: item,
        submitter: submitterOf(anna),
        initialChanges: TestFileIds(item.uuid.uuid).creation(),
      );

      expect(await remove(anna, item.uuid), isFalse);
      expect(await exists(item), isTrue);
    });

    test('when an unknown file is opened then nothing happens', () async {
      final item = await legacy();

      expect(
        await remove(anna, UuidValue.fromString(const Uuid().v7())),
        isFalse,
      );
      expect(await exists(item), isTrue);
    });
  });
}
