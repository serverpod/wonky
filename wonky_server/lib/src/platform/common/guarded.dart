import 'package:serverpod/serverpod.dart';

/// Runs one unit of background work — a scheduled job, one step of a job
/// chain, a queued task or one message of a long-lived loop — so that its
/// failure never escapes (specs/13 §3, server rule T2).
///
/// Any failure, an `Error` (`StateError`, `TypeError`, …) as well as an
/// `Exception`, is logged at error level with [name], the duration and the
/// stack trace, and the call returns null. On success it returns the body's
/// result and logs `name: <describe(result)> (<ms> ms)` when [describe]
/// gives a text. Jobs that return a count use [describeCount].
Future<T?> runGuarded<T>(
  Session session,
  String name,
  Future<T> Function() body, {
  String? Function(T result)? describe,
}) async {
  final watch = Stopwatch()..start();
  try {
    final result = await body();
    final text = describe?.call(result);
    if (text != null) {
      session.log('$name: $text (${watch.elapsedMilliseconds} ms)');
    }
    return result;
  } on Object catch (e, st) {
    session.log(
      '$name failed after ${watch.elapsedMilliseconds} ms: $e',
      level: LogLevel.error,
      exception: e,
      stackTrace: st,
    );
    return null;
  }
}

/// For [runGuarded]: describes a positive count, stays quiet for 0.
String? describeCount(int count) => count > 0 ? '$count' : null;
