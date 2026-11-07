import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/rate_limiter.dart';
import '../users/user_service.dart';

/// Signed-out viewers of link-shared documents, spreadsheets and
/// presentations (specs/06 §2.4, specs/13 §1).
///
/// The few endpoint methods that serve them (`sharing.publicItem`, the
/// read calls and streams of `document`, `sheetsDoc` and `slidesDoc`) take
/// the caller through [actorOf]: signed-in callers as usual, signed-out
/// ones as [Actor.anonymous] after the rate limits. What they may see is
/// decided by `AccessService` alone (Viewer on link-shared items).
abstract final class AnonymousAccess {
  /// Calls per client address and minute.
  static int callsPerAddress = 120;

  /// Streams opened per client address and minute.
  static int streamsPerAddress = 20;

  /// Calls of all signed-out callers together per minute: a bound that
  /// holds when addresses are forged through `Forwarded` headers or
  /// rotated.
  static int callsInTotal = 6000;

  /// Signed-out streams open at once on this instance.
  static int maxOpenStreams = 1000;

  static int _open = 0;

  /// Open signed-out streams on this instance (tests).
  static int get openStreams => _open;

  static final _perAddress = RateLimiter(
    name: 'anon.calls',
    window: const Duration(minutes: 1),
  );
  static final _streams = RateLimiter(
    name: 'anon.streams',
    window: const Duration(minutes: 1),
  );
  static final _total = RateLimiter(
    name: 'anon.total',
    window: const Duration(minutes: 1),
  );

  /// Clears the in-memory limits (tests).
  static void resetLimits() {
    _perAddress.reset();
    _streams.reset();
    _total.reset();
  }

  /// The caller: the signed-in user, or [Actor.anonymous] within the
  /// limits ([stream]: the call opens a stream).
  ///
  /// A request that carries an auth key which no longer validates (an
  /// expired access token) is refused as unauthenticated (HTTP 401), as on
  /// `requireLogin` endpoints, so the client refreshes its token instead of
  /// silently viewing signed out.
  static Future<Actor> actorOf(Session session, {bool stream = false}) async {
    if (session.authenticated != null) return UserService.actorOf(session);
    if (session.authenticationKey != null) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.unauthenticated,
      );
    }
    final address = clientAddress(session) ?? 'unknown';
    await _check(_perAddress, 'ip:$address', callsPerAddress);
    if (stream) await _check(_streams, 'ip:$address', streamsPerAddress);
    await _check(_total, 'all', callsInTotal);
    if (stream && _open >= maxOpenStreams) {
      throw Errors.limit(
        'Too many people are viewing signed out. Sign in to continue.',
      );
    }
    return Actor.anonymous;
  }

  /// [source] counted as an open signed-out stream while it is listened to
  /// (unchanged for a signed-in [actor]).
  static Stream<T> track<T>(Actor actor, Stream<T> source) {
    if (!actor.isAnonymous) return source;
    _open++;
    var released = false;
    void release() {
      if (released) return;
      released = true;
      _open--;
    }

    late final StreamController<T> out;
    StreamSubscription<T>? sub;
    out = StreamController<T>(
      onListen: () {
        sub = source.listen(
          out.add,
          onError: out.addError,
          onDone: () {
            release();
            unawaited(out.close());
          },
        );
      },
      onCancel: () async {
        release();
        await sub?.cancel();
      },
    );
    return out.stream;
  }

  /// The client address of [session]'s request (null without a request).
  static String? clientAddress(Session session) {
    try {
      return session.request?.remoteInfo;
    } on Object {
      return null;
    }
  }

  static Future<void> _check(RateLimiter limiter, String key, int max) async {
    final retry = await limiter.check(key, limit: max);
    if (retry == null) return;
    throw Errors.limit(
      'Too many requests. Sign in or try again in a minute.',
      detailsJson: jsonEncode({'retryAfterSeconds': retry.inSeconds}),
    );
  }
}
