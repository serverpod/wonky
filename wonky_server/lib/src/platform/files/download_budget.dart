import 'package:clock/clock.dart';

import '../common/lru_map.dart';

/// The daily download allowance of each user (suite 13 §6: 2 GB per user
/// and day, `files.downloadBytesPerDay`), counted per instance and UTC day
/// (soft with several instances, 13 §4). Bounded: at most [maxUsers]
/// users are tracked per instance.
abstract final class DownloadBudget {
  static const maxUsers = 100000;

  static final LruMap<int, ({String day, int bytes})> _used = LruMap(maxUsers);

  static String _today() =>
      clock.now().toUtc().toIso8601String().substring(0, 10);

  /// Charges [bytes] to [userId] if today's total stays within [limit];
  /// returns whether it was charged.
  static bool tryCharge(int userId, int bytes, {required int limit}) {
    final day = _today();
    final current = _used.get(userId);
    final used = current?.day == day ? current!.bytes : 0;
    if (used + bytes > limit) return false;
    _used.put(userId, (day: day, bytes: used + bytes));
    return true;
  }

  /// Bytes [userId] downloaded today on this instance.
  static int usedToday(int userId) {
    final current = _used.peek(userId);
    return current?.day == _today() ? current!.bytes : 0;
  }

  /// Forgets every count (tests).
  static void clear() => _used.clear();
}
