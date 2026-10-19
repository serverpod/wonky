@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod_auth_idp_server/core.dart' as auth;
import 'package:serverpod_auth_idp_server/providers/google.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/users/google_idp.dart';

import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a first sign-in with Google', (
    sessionBuilder,
    endpoints,
  ) {
    /// What the Google IDP does for an unknown Google account: a new auth
    /// user with the Google account linked to it.
    Future<(auth.AuthUserModel, GoogleAccount)> newGoogleAccount(
      String email,
    ) async {
      final session = sessionBuilder.build();
      final user = await auth.AuthUser.db.insertRow(
        session,
        auth.AuthUser(scopeNames: {}, blocked: false),
      );
      final account = await GoogleAccount.db.insertRow(
        session,
        GoogleAccount(
          authUserId: user.id!,
          email: email,
          userIdentifier: 'google-$email',
        ),
      );
      return (
        auth.AuthUserModel(
          id: user.id!,
          createdAt: user.createdAt,
          scopeNames: {},
          blocked: false,
        ),
        account,
      );
    }

    test(
      'when an account with the same email exists then the Google login is '
      'linked to it and no second account is created',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final session = sessionBuilder.build();
        final (authUser, account) = await newGoogleAccount(
          anna.email.toUpperCase(),
        );

        await afterGoogleAccountCreated(
          session,
          authUser,
          account,
          transaction: null,
        );

        // The sign-in in progress returns Anna's account.
        expect(account.authUserId, anna.authUserId);
        final stored = await GoogleAccount.db.findById(session, account.id!);
        expect(stored!.authUserId, anna.authUserId);
        expect(await auth.AuthUser.db.findById(session, authUser.id), isNull);
        final profiles = await UserProfile.db.find(
          session,
          where: (t) => t.email.equals(anna.email),
        );
        expect(profiles, hasLength(1));
      },
    );

    test(
      'when the email is new then a profile is created with the Google name',
      () async {
        final session = sessionBuilder.build();
        final email = 'new.${clock.now().microsecondsSinceEpoch}@example.test';
        final (authUser, account) = await newGoogleAccount(email);

        await rememberGoogleDetails(
          session,
          accountDetails: (
            userIdentifier: 'google-$email',
            email: email,
            name: 'Grace',
            fullName: 'Grace Hopper',
            image: null,
            verifiedEmail: true,
          ),
          accessToken: 'token',
          transaction: null,
        );
        await afterGoogleAccountCreated(
          session,
          authUser,
          account,
          transaction: null,
        );

        final profile = await UserProfile.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(authUser.id),
        );
        expect(profile!.email, email);
        expect(profile.displayName, 'Grace Hopper');
        expect(account.authUserId, authUser.id);
      },
    );
  });
}
