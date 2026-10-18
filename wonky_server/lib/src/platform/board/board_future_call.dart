import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import 'board_pipeline.dart';
import 'board_sweep.dart';
import 'board_tasks.dart';

/// Background work of Bugs & improvements (specs/16 §6.3, §8.2): the
/// background triage with retries, the writing pass, the task prompt
/// (specs/16 §10.1) and the recurring sweep (`wonky.boardSweep`, every 10
/// minutes).
class BoardFutureCall extends FutureCall {
  Future<void> triage(Session session, int postId) =>
      _run(session, 'triage #$postId', () async {
        await BoardPipeline.backgroundTriage(session, postId);
        return 0;
      });

  Future<void> summarize(Session session, int postId) =>
      _run(session, 'summarize #$postId', () async {
        await BoardPipeline.summarize(session, postId);
        return 0;
      });

  Future<void> writePrompt(Session session, int taskId) =>
      _run(session, 'writePrompt T-$taskId', () async {
        await BoardTasks.writePrompt(session, taskId);
        return 0;
      });

  Future<void> sweep(Session session) =>
      _run(session, 'sweep', () => BoardSweep.run(session));

  Future<void> _run(
    Session session,
    String name,
    Future<int> Function() job,
  ) => runGuarded<int>(session, 'board.$name', job, describe: describeCount);
}
