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
      'when the Google login is linked to an existing account then the IDP '
      'keeps its auth profile instead of creating a second one',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final session = sessionBuilder.build();
        // The auth profile the email sign-up created.
        await auth.UserProfile.db.insertRow(
          session,
          auth.UserProfile(authUserId: anna.authUserId, email: anna.email),
        );
        final (authUser, account) = await newGoogleAccount(anna.email);
        await afterGoogleAccountCreated(
          session,
          authUser,
          account,
          transaction: null,
        );

        // What `GoogleIdp.login` does next for a new Google account.
        await const LinkedAccountUserProfiles().createUserProfile(
          session,
          account.authUserId,
          auth.UserProfileData(fullName: 'Anna Google', email: anna.email),
        );

        final profiles = await auth.UserProfile.db.find(
          session,
          where: (t) => t.authUserId.equals(anna.authUserId),
        );
        expect(profiles, hasLength(1));
        expect(profiles.single.fullName, isNull);
      },
    );

    test(
      'when the Google account is new then the IDP creates its auth profile',
      () async {
        final session = sessionBuilder.build();
        final email = 'new.${clock.now().microsecondsSinceEpoch}@example.test';
        final (authUser, _) = await newGoogleAccount(email);

        await const LinkedAccountUserProfiles().createUserProfile(
          session,
          authUser.id,
          auth.UserProfileData(fullName: 'Grace Hopper', email: email),
        );

        final profile = await auth.UserProfile.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(authUser.id),
        );
        expect(profile!.fullName, 'Grace Hopper');
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
