import 'package:serverpod/serverpod.dart';

import '../../platform/common/guarded.dart';
import 'script_jobs.dart';
import 'script_executions.dart';
import 'script_triggers.dart';

/// Scheduled script jobs (Sheets 09 §8.7.3, §13.1): the time-driven trigger
/// tick (every minute) and the daily executions pruning.
class ScriptSchedulerFutureCall extends FutureCall {
  /// Every minute: runs due time-driven triggers.
  Future<void> tick(Session session) => runGuarded<int>(
    session,
    'scripts.tick',
    () => ScriptTriggerService.tick(session),
    describe: describeCount,
  );

  /// Daily: executions older than 30 days or beyond 10,000 per spreadsheet.
  Future<void> prune(Session session) => runGuarded<(int, int)>(
    session,
    'scripts.prune',
    () async {
      final n = await ScriptExecutions.pruneExecutions(session);
      final jobs = await ScriptJobQueue.prune(session);
      return (n, jobs);
    },
    describe: (r) =>
        r.$1 + r.$2 > 0 ? '${r.$1} executions, ${r.$2} jobs' : null,
  );
}
