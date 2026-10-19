import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_server/src/platform/board/ai/board_ai.dart';
import 'package:wonky_server/src/platform/board/board_common.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/board/board_tasks.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../test_users.dart';
import '../wonky_serverpod.dart';
import 'fake_board_ai.dart';

/// A scheduled background job (recorded instead of a future call); [id] is
/// a post id, or a task id for [BoardJob.prompt].
typedef ScheduledBoardJob = ({BoardJob job, int id, Duration delay});

/// Test setup of the board: a [FakeBoardAi], default config, recorded jobs.
class BoardHarness {
  BoardHarness._(this.ai);

  final FakeBoardAi ai;
  final scheduled = <ScheduledBoardJob>[];

  static var _seq = 0;

  /// Installs the fakes; call [uninstall] in `tearDown`.
  static BoardHarness install({BoardConfig? config}) {
    final h = BoardHarness._(FakeBoardAi());
    BoardAi.override = h.ai;
    BoardConfig.current = config ?? BoardConfig();
    BoardRateLimits.reset();
    BoardJobs.scheduler = (session, job, id, delay) async =>
        h.scheduled.add((job: job, id: id, delay: delay));
    return h;
  }

  void uninstall() {
    BoardAi.override = null;
    BoardConfig.current = BoardConfig();
    BoardRateLimits.reset();
  }

  /// A word no other test uses (full-text search isolation).
  static String word() {
    _seq++;
    var n = clock.now().microsecondsSinceEpoch * 100 + _seq;
    final b = StringBuffer('qz');
    while (n > 0) {
      b.writeCharCode(97 + n % 26);
      n ~/= 26;
    }
    return b.toString();
  }

  /// A board admin: a user whose email is in `serverpod.dev`.
  static Future<TestUser> admin(
    TestSessionBuilder sessionBuilder, {
    String name = 'Admin',
  }) async {
    final user = await TestUsers.create(sessionBuilder, name: name);
    final session = sessionBuilder.build();
    await UserProfile.db.updateRow(
      session,
      user.profile.copyWith(
        email: '${name.toLowerCase()}.${word()}@serverpod.dev',
      ),
    );
    return user;
  }

  static BoardPostDraft draft({
    BoardPostKind kind = BoardPostKind.bug,
    String? title,
    String? body,
    UuidValue? screenshot,
  }) => BoardPostDraft(
    kind: kind,
    title: title ?? 'Something is broken ${word()}',
    body: body ?? 'It does not work as expected.',
    appHint: 'sheets',
    screenshotFileUuid: screenshot,
  );

  static Future<BoardPostView> post(
    TestEndpoints endpoints,
    TestUser author, {
    BoardPostKind kind = BoardPostKind.bug,
    String? title,
    String? body,
  }) => endpoints.board.createPost(
    author.endpointSession,
    draft(kind: kind, title: title, body: body),
  );

  /// A published task of [posts] (created by [admin]).
  static Future<BoardTaskView> publishedTask(
    TestEndpoints endpoints,
    TestUser admin,
    List<int> posts, {
    String title = 'Fix the thing',
  }) async {
    final task = await endpoints.board.createTask(
      admin.endpointSession,
      posts,
      title,
      BoardArea.sheets,
      BoardSize.small,
    );
    return endpoints.board.publishTask(admin.endpointSession, task.number);
  }

  /// Claim codes look like `XXXX-XXXX` in the Crockford alphabet.
  static final claimCode = RegExp(
    '^[${BoardTasks.claimAlphabet}]{4}-[${BoardTasks.claimAlphabet}]{4}\$',
  );
}
