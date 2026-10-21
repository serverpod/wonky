import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:wonky_app/src/auth/shared_session.dart';

final _now = DateTime.utc(2026, 10, 21, 12);
final _user = UuidValue.fromString('0195a3c8-0000-7000-8000-000000000001');

AuthSuccess _session(String refreshToken, {required Duration validFor}) =>
    AuthSuccess(
      authStrategy: 'jwt',
      token: 'access-$refreshToken',
      tokenExpiresAt: _now.add(validFor),
      refreshToken: refreshToken,
      authUserId: _user,
      scopeNames: {},
    );

/// The browser's `localStorage`: one session shared by every tab.
class _SharedStorage implements ClientAuthSuccessStorage {
  AuthSuccess? data;

  @override
  Future<AuthSuccess?> get() async => data;

  @override
  Future<void> set(AuthSuccess? data) async => this.data = data;
}

/// The Web Locks lock: one holder at a time, in request order.
class _Lock implements CrossTabLock {
  Future<void> _tail = Future.value();

  @override
  Future<T> synchronize<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (Object _) {});
    return result;
  }
}

/// The JWT refresh endpoint: rotates the single-use refresh token and, like
/// Serverpod, revokes the session when an already rotated one comes back.
class _Server {
  int _secret = 0;
  int rotations = 0;
  bool revoked = false;

  /// While set, refresh calls wait for it (a request in flight).
  Completer<void>? hold;

  /// Thrown by the next refresh calls (e.g. a network error).
  Object? failWith;

  String get current => 'r$_secret';

  Future<AuthSuccess> refresh(String refreshToken) async {
    await hold?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    if (revoked) throw RefreshTokenNotFoundException();
    if (refreshToken != current) {
      revoked = true;
      throw RefreshTokenInvalidSecretException();
    }
    _secret++;
    rotations++;
    return _session(current, validFor: const Duration(minutes: 10));
  }
}

SharedJwtAuthKeyProvider _tab(
  _SharedStorage storage,
  _Server server,
  _Lock lock,
) => SharedJwtAuthKeyProvider(
  storage: storage,
  refresh: server.refresh,
  onRefreshed: storage.set,
  crossTabLock: () => lock,
);

void main() {
  late _SharedStorage storage;
  late _Server server;
  late _Lock lock;

  setUp(() {
    storage = _SharedStorage();
    server = _Server();
    lock = _Lock();
  });

  Future<void> atNow(Future<void> Function() body) =>
      withClock(Clock.fixed(_now), body);

  group('Given two tabs sharing a session whose token is about to expire', () {
    setUp(
      () =>
          storage.data = _session('r0', validFor: const Duration(seconds: 10)),
    );

    test(
      'when both refresh at once then the token rotates once and both use it',
      () => atNow(() async {
        final first = _tab(storage, server, lock);
        final second = _tab(storage, server, lock);
        server.hold = Completer();

        final refreshes = [first.refreshAuthKey(), second.refreshAuthKey()];
        await pumpEventQueue();
        server.hold!.complete();

        expect(await Future.wait(refreshes), [
          RefreshAuthKeyResult.success,
          RefreshAuthKeyResult.success,
        ]);
        expect(server.rotations, 1);
        expect(server.revoked, isFalse);
        expect(await second.authHeaderValue, contains('access-r1'));
      }),
    );

    test(
      'when one tab refreshed first then the other one makes no call',
      () => atNow(() async {
        await _tab(storage, server, lock).refreshAuthKey();

        final result = await _tab(storage, server, lock).refreshAuthKey();

        expect(result, RefreshAuthKeyResult.skipped);
        expect(server.rotations, 1);
      }),
    );
  });

  group('Given a session with a valid token', () {
    setUp(
      () => storage.data = _session('r0', validFor: const Duration(minutes: 5)),
    );

    test(
      'when refreshing without force then the token is kept',
      () => atNow(() async {
        final result = await _tab(storage, server, lock).refreshAuthKey();

        expect(result, RefreshAuthKeyResult.skipped);
        expect(server.rotations, 0);
      }),
    );

    test(
      'when another tab signed out then a forced refresh makes no call',
      () => atNow(() async {
        final tab = _tab(storage, server, lock);
        storage.data = null;

        final result = await tab.refreshAuthKey(force: true);

        expect(result, RefreshAuthKeyResult.skipped);
        expect(server.rotations, 0);
      }),
    );

    test(
      'when the server rejects the refresh token then the refresh is unauthorized',
      () => atNow(() async {
        server.revoked = true;

        final result = await _tab(
          storage,
          server,
          lock,
        ).refreshAuthKey(force: true);

        expect(result, RefreshAuthKeyResult.failedUnauthorized);
      }),
    );

    test(
      'when the refresh fails on the network then the session is kept',
      () => atNow(() async {
        server.failWith = const ServerpodClientNetworkException('offline');

        final result = await _tab(
          storage,
          server,
          lock,
        ).refreshAuthKey(force: true);

        expect(result, RefreshAuthKeyResult.failedOther);
        expect(storage.data?.refreshToken, 'r0');
      }),
    );
  });

  group('Given a refresh call in flight', () {
    late SharedJwtAuthKeyProvider tab;
    late Future<RefreshAuthKeyResult> refresh;

    setUp(() async {
      storage.data = _session('r0', validFor: const Duration(minutes: 5));
      tab = _tab(storage, server, lock);
      server.hold = Completer();
      refresh = tab.refreshAuthKey(force: true);
      await pumpEventQueue();
    });

    test(
      'when waiting for it to settle then it waits for the response',
      () async {
        var settled = false;
        unawaited(tab.settled.then((_) => settled = true));
        await pumpEventQueue();
        expect(settled, isFalse);

        server.hold!.complete();
        await refresh;
        await pumpEventQueue();

        expect(settled, isTrue);
        expect(storage.data?.refreshToken, 'r1');
      },
    );
  });

  group('Given a page load with a restored session', () {
    late FlutterAuthSessionManager auth;
    late int signedInChecks;
    late List<bool> serverAccepts;

    Future<bool> isSignedIn() async {
      signedInChecks++;
      return serverAccepts.removeAt(0);
    }

    setUp(() {
      signedInChecks = 0;
      serverAccepts = [true];
      late final FlutterAuthSessionManager manager;
      final keys = SharedJwtAuthKeyProvider(
        storage: storage,
        refresh: server.refresh,
        onRefreshed: (a) => manager.updateSignedInUser(a),
        crossTabLock: () => lock,
      );
      auth = manager = FlutterAuthSessionManager(
        storage: storage,
        authKeyProviderDelegates: {'jwt': keys},
      );
    });

    test(
      'when the token is still valid then it is checked without rotating',
      () => atNow(() async {
        storage.data = _session('r0', validFor: const Duration(minutes: 5));

        await validateSharedSession(auth: auth, isSignedIn: isSignedIn);

        expect(server.rotations, 0);
        expect(signedInChecks, 1);
        expect(auth.isAuthenticated, isTrue);
      }),
    );

    test(
      'when the token is about to expire then it rotates once',
      () => atNow(() async {
        storage.data = _session('r0', validFor: const Duration(seconds: 10));

        await validateSharedSession(auth: auth, isSignedIn: isSignedIn);

        expect(server.rotations, 1);
        expect(auth.authInfo?.refreshToken, 'r1');
      }),
    );

    test(
      'when the server rejects a token that looks valid then it rotates once',
      () => atNow(() async {
        storage.data = _session('r0', validFor: const Duration(minutes: 5));
        serverAccepts = [false, true];

        await validateSharedSession(auth: auth, isSignedIn: isSignedIn);

        expect(server.rotations, 1);
        expect(signedInChecks, 2);
        expect(auth.isAuthenticated, isTrue);
      }),
    );
  });

  group('Given a session in the legacy storage only', () {
    late _SharedStorage legacy;
    late MigratingAuthSuccessStorage migrating;

    setUp(() {
      legacy = _SharedStorage()
        ..data = _session('r0', validFor: const Duration(minutes: 5));
      migrating = MigratingAuthSuccessStorage(storage: storage, legacy: legacy);
    });

    test('when reading it then it moves to the shared storage', () async {
      final data = await migrating.get();

      expect(data?.refreshToken, 'r0');
      expect(storage.data?.refreshToken, 'r0');
      expect(legacy.data, isNull);
    });

    test('when signing in then the legacy copy is cleared', () async {
      await migrating.set(_session('r9', validFor: const Duration(minutes: 5)));

      expect(storage.data?.refreshToken, 'r9');
      expect(legacy.data, isNull);
    });
  });
}
