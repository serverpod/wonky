import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart' as auth;
import 'package:wonky_server/src/platform/common/actor.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/users/user_service.dart';

import 'wonky_serverpod.dart';

/// A signed-in test user.
class TestUser {
  TestUser._(this.profile, this.endpointSession, this.name);

  final UserProfile profile;
  final String name;

  /// Session builder authenticated as this user (for `endpoints.*`).
  final TestSessionBuilder endpointSession;

  int get id => profile.id!;
  UuidValue get authUserId => profile.authUserId;
  String get email => profile.email;

  Actor get actor => Actor(userId: id, authUserId: authUserId);

  /// A server session for direct service calls.
  Session get session => endpointSession.build();
}

/// Creates test users (auth user + profile + preferences).
abstract final class TestUsers {
  static var _counter = 0;

  static Future<TestUser> create(
    TestSessionBuilder sessionBuilder, {
    String name = 'User',
  }) async {
    final session = sessionBuilder.build();
    final authUser = await auth.AuthUser.db.insertRow(
      session,
      auth.AuthUser(scopeNames: {}, blocked: false),
    );
    _counter++;
    final email =
        '${name.toLowerCase().replaceAll(' ', '.')}.${clock.now().microsecondsSinceEpoch}.$_counter@example.test';
    final profile = await UserService.ensureProfile(
      session,
      authUser.id!,
      email: email,
      displayName: name,
    );
    return TestUser._(
      profile,
      sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          authUser.id!.uuid,
          <Scope>{},
        ),
      ),
      name,
    );
  }

  static TestSessionBuilder unauthenticated(TestSessionBuilder builder) =>
      builder.copyWith(
        authentication: AuthenticationOverride.unauthenticated(),
      );
}
