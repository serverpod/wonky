import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import '../common/models.dart';
import 'acl_events.dart';

/// The drive fan-out of a permission change on a big folder, run right
/// after the request (`AclEvents.changed`, CQ-26).
class AclFutureCall extends FutureCall {
  Future<void> fanOut(
    Session session,
    int itemId,
    String kind,
    List<int> affectedUsers,
  ) => runGuarded<int>(
    session,
    'ACL fan-out of item $itemId',
    () => AclEvents.fanOutDeferred(
      session,
      itemId,
      DriveChangeKind.values.byName(kind),
      affectedUsers.toSet(),
    ),
    describe: describeCount,
  );
}
