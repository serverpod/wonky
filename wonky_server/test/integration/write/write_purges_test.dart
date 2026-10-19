@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/common/time.dart';
import 'package:wonky_server/src/write/ot/document_store.dart';
import 'package:wonky_server/src/write/themes/theme_service.dart';
import 'package:wonky_server/src/write/versions/write_history_service.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show BuiltinThemes;

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

final _json = jsonEncode(BuiltinThemes.wonkyDefault.json);

/// The daily Write purges (CQ-59): deleted themes after their retention
/// unless a document still uses them, and the version diff cache.
void main() {
  withWonkyServerpod('Given deleted user themes', (sessionBuilder, endpoints) {
    late TestUser anna;
    late Session session;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      session = sessionBuilder.build();
    });

    Future<WriteThemeView> deletedTheme(String name) async {
      final theme = await endpoints.writeTheme.create(
        anna.endpointSession,
        name,
        _json,
        null,
      );
      await endpoints.writeTheme.delete(anna.endpointSession, theme.uuid);
      return theme;
    }

    Future<bool> exists(WriteThemeView theme) async =>
        await WriteTheme.db.findFirstRow(
          session,
          where: (t) => t.uuid.equals(theme.uuid),
        ) !=
        null;

    test('when the retention has passed then an unused deleted theme is '
        'removed and a recent one stays', () async {
      final old = await deletedTheme('Old');
      final recent = await deletedTheme('Recent');
      final now = nowUtc().add(
        ThemeService.deletedRetention + const Duration(hours: 1),
      );
      await WriteTheme.db.updateWhere(
        session,
        columnValues: (t) => [
          t.deletedAt(now.subtract(const Duration(days: 1))),
        ],
        where: (t) => t.uuid.equals(recent.uuid),
      );

      final purged = await ThemeService.purgeDeleted(session, now: now);

      expect(purged, greaterThanOrEqualTo(1));
      expect(await exists(old), isFalse);
      expect(await exists(recent), isTrue);
    });

    test(
      'when a document still uses a deleted theme then it is kept',
      () async {
        final used = await deletedTheme('Used');
        final doc = await TestDrive.document(endpoints, anna);
        await Document.db.updateWhere(
          session,
          columnValues: (t) => [t.themeId(used.uuid)],
          where: (t) => t.uuid.equals(doc.contentRef!),
        );

        await ThemeService.purgeDeleted(
          session,
          now: nowUtc().add(ThemeService.deletedRetention * 2),
        );

        expect(await exists(used), isTrue);
      },
    );
  });

  withWonkyServerpod('Given cached version diffs', (sessionBuilder, endpoints) {
    test('when the diff cache retention has passed then old entries are '
        'deleted and fresh ones stay', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final session = sessionBuilder.build();
      final item = await TestDrive.document(endpoints, anna);
      final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
      final now = nowUtc();
      Future<void> cache(int to, DateTime at) => WriteDiffCache.db.insertRow(
        session,
        WriteDiffCache(
          documentId: doc.id!,
          fromRevision: 0,
          toRevision: to,
          json: '{}',
          createdAt: at,
        ),
      );
      await cache(1, now.subtract(WriteHistoryService.diffCacheRetention * 2));
      await cache(2, now);

      final purged = await WriteHistoryService.purgeDiffCache(
        session,
        now: now,
      );

      final left = await WriteDiffCache.db.find(
        session,
        where: (t) => t.documentId.equals(doc.id!),
      );
      expect(purged, greaterThanOrEqualTo(1));
      expect(left.map((c) => c.toRevision), [2]);
    });
  });
}
