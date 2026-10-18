import 'package:serverpod/serverpod.dart';

import '../revlog/rev_jobs.dart';
import '../revlog/server_change_records.dart';
import '../../write/ot/document_service.dart';
import '../../write/themes/theme_service.dart';
import '../../write/versions/write_history_service.dart';
import '../ai/ai_usage_service.dart';
import '../common/guarded.dart';
import '../drive/drive_file_service.dart';
import '../drive/drive_trash.dart';
import '../drive/kind_masks.dart';
import '../files/file_service.dart';
import '../notifications/notification_service.dart';
import '../sharing/sharing_service.dart';
import '../versions/version_service.dart';

/// Scheduled jobs (specs/13 §3). Each job is idempotent; schedules are
/// registered at server start (`registerMaintenanceJobs`).
class MaintenanceFutureCall extends FutureCall {
  /// Runs one job through [runGuarded]: any failure (an `Error` too) is
  /// logged at error level with the job's name and duration, and never
  /// stops the jobs after it.
  Future<void> _run(
    Session session,
    String name,
    Future<int> Function() job,
  ) => runGuarded<int>(session, name, job, describe: describeCount);

  /// Every minute: version capture policy.
  Future<void> captureVersions(Session session) => _run(
    session,
    'versions.capture',
    () => VersionService.captureDue(session),
  );

  /// Every 15 minutes: notification email digests.
  Future<void> sendDigests(Session session) => _run(
    session,
    'notifications.digest',
    () => NotificationService.sendDigests(session),
  );

  /// Hourly: expired files (imports, exports) and abandoned uploads.
  Future<void> cleanupFiles(Session session) => _run(
    session,
    'files.cleanup',
    () => FileService.cleanupExpired(session),
  );

  /// Every 5 minutes: RevLog hook sweep (RevLog spec 05 §10): files whose
  /// post-commit hooks lag or whose retry is due.
  Future<void> revlogSweep(Session session) =>
      _run(session, 'revlog.hookSweep', () => RevJobs.hookSweep(session));

  /// Hourly: expired grants (specs/06 §2: access ends at expiry, also for
  /// open sync spaces and documents), until none are left.
  Future<void> expireGrants(Session session) => _run(
    session,
    'sharing.expiredGrants',
    () => SharingService.removeExpiredGrants(session),
  );

  /// Daily: trash purge, (v2) expired uploads and folder kind masks,
  /// version thinning, op-log and change-log pruning, active-set eviction,
  /// server change records, deleted themes, the diff cache, old AI usage
  /// and old notifications.
  Future<void> daily(Session session) async {
    await _run(
      session,
      'drive.purgeTrash',
      () => DriveTrash.purgeExpiredTrash(session),
    );
    await _run(
      session,
      'drive.expireUploads',
      () => DriveFileService.expireUploads(session),
    );
    await _run(
      session,
      'drive.recomputeKindMasks',
      () => KindMasks.recomputeAll(session),
    );
    await _run(session, 'versions.thin', () => VersionService.thin(session));
    await _run(
      session,
      'write.pruneOps',
      () => DocumentService.pruneOps(session),
    );
    await _run(session, 'revlog.pruneOps', () => RevJobs.pruneOps(session));
    if (DateTime.now().toUtc().weekday == DateTime.sunday) {
      await _run(
        session,
        'revlog.repairStats',
        () => RevJobs.repairStats(session),
      );
    }
    await _run(
      session,
      'revlog.purgeServerChanges',
      () => ServerChangeRecords.purgeExpired(session),
    );
    await _run(
      session,
      'write.purgeDeletedThemes',
      () => ThemeService.purgeDeleted(session),
    );
    await _run(
      session,
      'write.purgeDiffCache',
      () => WriteHistoryService.purgeDiffCache(session),
    );
    await _run(session, 'ai.purgeUsage', () => AiUsageService.purge(session));
    await _run(
      session,
      'notifications.purgeOld',
      () => NotificationService.purgeOld(session),
    );
  }
}
