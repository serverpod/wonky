import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import 'content_sizes.dart';
import 'storage_maintenance.dart';

/// Storage jobs (Drive 03 §4.3, §9): the backfill scheduled at server
/// start, the nightly reconcile and trailing size estimates of spaces.
class StorageFutureCall extends FutureCall {
  /// Backfill of users without reconciled counters (idempotent,
  /// resumable; serialized across instances).
  Future<void> backfill(Session session) => runGuarded<int>(
    session,
    'storage.backfill',
    () => StorageMaintenance.backfillPending(session),
    describe: (n) => n > 0 ? '$n users' : null,
  );

  /// Nightly: recomputes every user's counters from the sources.
  Future<void> reconcile(Session session) => runGuarded<int>(
    session,
    'storage.reconcile',
    () => StorageMaintenance.reconcileAll(session),
    describe: (n) => n > 0 ? '$n users with drift' : null,
  );

  /// The trailing size estimate of a space item (Drive 03 §2 cadence).
  Future<void> refreshItemSize(Session session, int itemId) => runGuarded(
    session,
    'storage.refreshItemSize $itemId',
    () => ContentSizes.refreshById(session, itemId),
  );
}
