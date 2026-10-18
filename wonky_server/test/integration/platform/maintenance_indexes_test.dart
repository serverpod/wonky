@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';

import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// The indexes behind the recurring jobs and the stored-file cleanup that
/// uses them (code-quality CQ-27, specs/13 §3).
void main() {
  withWonkyServerpod('Given the database schema', (sessionBuilder, endpoints) {
    test('when listing the indexes then the job indexes exist', () async {
      final rows = await sessionBuilder.build().db.unsafeQuery(
        "SELECT indexname FROM pg_indexes WHERE schemaname = 'public'",
      );
      final names = {for (final r in rows) r[0]};

      expect(
        names,
        containsAll([
          'stored_file_owner_kind_idx',
          'stored_file_status_idx',
          'drive_item_trashed_idx',
          'perm_expires_idx',
          'notification_email_idx',
          'notification_created_idx',
          'write_diff_cache_created_idx',
          'document_op_created_idx',
        ]),
      );
    });
  });

  withWonkyServerpod('Given expired and abandoned files', (
    sessionBuilder,
    endpoints,
  ) {
    test('when the cleanup runs then expired files and day-old pending '
        'uploads go and fresh uploads stay', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final session = sessionBuilder.build();
      final now = clock.now().toUtc();
      StoredFile file(
        String name,
        StoredFileStatus status,
        DateTime created, {
        DateTime? expires,
      }) => StoredFile(
        fileUuid: const Uuid().v7obj(),
        ownerId: anna.id,
        kind: StoredFileKind.exportResult,
        storageId: 'private',
        path: 'test/${const Uuid().v4()}/$name',
        fileName: name,
        mimeType: 'application/pdf',
        sizeBytes: 1,
        status: status,
        createdAt: created,
        expiresAt: expires,
      );
      final rows = await StoredFile.db.insert(session, [
        file(
          'expired',
          StoredFileStatus.ready,
          now.subtract(const Duration(hours: 3)),
          expires: now.subtract(const Duration(hours: 1)),
        ),
        file(
          'abandoned',
          StoredFileStatus.pending,
          now.subtract(const Duration(days: 2)),
        ),
        file('uploading', StoredFileStatus.pending, now),
        file(
          'kept',
          StoredFileStatus.ready,
          now,
          expires: now.add(const Duration(hours: 1)),
        ),
      ]);

      await FileService.cleanupExpired(session, now: now);
      final left = await StoredFile.db.find(
        session,
        where: (t) => t.id.inSet(<int>{for (final r in rows) r.id!}),
      );

      expect(
        left.map((f) => f.fileName),
        unorderedEquals([
          'uploading',
          'kept',
        ]),
      );
    });
  });
}
