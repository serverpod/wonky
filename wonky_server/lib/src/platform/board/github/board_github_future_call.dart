import 'package:serverpod/serverpod.dart';

import '../../common/guarded.dart';
import 'board_github.dart';
import 'github_review.dart';

/// Background work of the GitHub App (specs/16 §13): handling a stored
/// webhook delivery, and the debounced task review.
class BoardGithubFutureCall extends FutureCall {
  Future<void> handle(Session session, String deliveryId) => runGuarded(
    session,
    'board.github: delivery $deliveryId',
    () => BoardGithub.handleDelivery(session, deliveryId),
  );

  Future<void> review(Session session, int prNumber, String headSha) =>
      runGuarded(
        session,
        'board.github: review of #$prNumber',
        () => GithubReview.run(session, prNumber, headSha),
      );
}
