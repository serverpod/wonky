@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/themes/builtin_theme_ids.dart';

import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a new user', (sessionBuilder, endpoints) {
    test('when calling getMe then the profile is returned', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna Berg');

      final me = await endpoints.user.getMe(anna.endpointSession);

      expect(me.summary.displayName, 'Anna Berg');
      expect(me.summary.uuid, anna.authUserId);
    });

    test(
      'when calling getMe then the welcome document is created once',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');

        await endpoints.user.getMe(anna.endpointSession);
        await endpoints.user.getMe(anna.endpointSession);
        final page = await endpoints.drive.list(
          anna.endpointSession,
          null,
          DriveListFilter(kinds: [DriveItemKind.document]),
          DriveSort(),
          null,
          50,
        );

        expect(page.items.map((i) => i.name), ['New here? Read me first']);
        // It opens Pageless, like every new document (T-1).
        final item = await DriveItem.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.uuid.equals(page.items.single.uuid),
        );
        final doc = await Document.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.itemId.equals(item!.id),
        );
        expect(jsonDecode(doc!.pageSetupJson)['layout'], 'pageless');
      },
    );

    test(
      'when calling getMe and updateProfile concurrently then the welcome '
      'content is created once',
      () async {
        // The sign-up flow calls getMe and updateProfile at the same time; a
        // full-row profile write from a stale read used to reset the welcome
        // claim, so a second getMe created the content again.
        for (var round = 0; round < 6; round++) {
          final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
          await Future.wait([
            endpoints.user.getMe(anna.endpointSession),
            for (var i = 0; i < 3; i++) ...[
              endpoints.user.updateProfile(
                anna.endpointSession,
                displayName: 'Anna $i',
              ),
              endpoints.user.getMe(anna.endpointSession),
            ],
          ]);
          final page = await endpoints.drive.list(
            anna.endpointSession,
            null,
            DriveListFilter(),
            DriveSort(),
            null,
            50,
          );

          expect(page.items.map((i) => i.name), [
            'New here? Read me first',
          ], reason: 'round $round');
        }
      },
    );

    test(
      'when calling getMe then only the Write welcome document is created',
      () async {
        // No welcome spreadsheet or presentation (T-19, specs/04 §1.1).
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');

        await endpoints.user.getMe(anna.endpointSession);
        final page = await endpoints.drive.list(
          anna.endpointSession,
          null,
          DriveListFilter(),
          DriveSort(),
          null,
          50,
        );

        expect(page.items.map((i) => (i.kind, i.name)), [
          (DriveItemKind.document, 'New here? Read me first'),
        ]);
        expect(
          await Spreadsheet.db.count(sessionBuilder.build()),
          0,
          reason: 'no spreadsheet row either',
        );
      },
    );

    test(
      'when reading preferences then the default theme is Wonky Default',
      () async {
        final anna = await TestUsers.create(sessionBuilder);

        final prefs = await endpoints.user.getPreferences(anna.endpointSession);

        expect(
          jsonDecode(prefs.writeDefaults)['defaultThemeId'],
          BuiltinThemeIds.wonkyDefault.uuid,
        );
      },
    );

    test('when patching JSON preferences then keys are merged', () async {
      final anna = await TestUsers.create(sessionBuilder);
      await endpoints.user.updatePreferences(
        anna.endpointSession,
        UserPreferencesPatch(writeDefaults: jsonEncode({'spellcheck': false})),
      );

      final prefs = await endpoints.user.updatePreferences(
        anna.endpointSession,
        UserPreferencesPatch(appTheme: AppThemeMode.dark),
      );

      final defaults = jsonDecode(prefs.writeDefaults) as Map;
      expect(prefs.appTheme, AppThemeMode.dark);
      expect(defaults['spellcheck'], false);
      expect(defaults['defaultThemeId'], BuiltinThemeIds.wonkyDefault.uuid);
    });

    test('when updating the display name then getMe returns it', () async {
      final anna = await TestUsers.create(sessionBuilder);

      await endpoints.user.updateProfile(
        anna.endpointSession,
        displayName: '  Anna  B. ',
      );

      final me = await endpoints.user.getMe(anna.endpointSession);
      expect(me.summary.displayName, 'Anna B.');
    });

    test('when updating with an empty name then it is refused', () async {
      final anna = await TestUsers.create(sessionBuilder);

      await expectLater(
        endpoints.user.updateProfile(anna.endpointSession, displayName: ' '),
        throwsA(isA<WonkyException>()),
      );
    });
  });

  withWonkyServerpod('Given two users without shared items', (
    sessionBuilder,
    endpoints,
  ) {
    test('when searching by name then the other user is not found', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      await TestUsers.create(sessionBuilder, name: 'Zed Unique');

      final found = await endpoints.user.searchUsers(
        anna.endpointSession,
        'zed',
        10,
      );

      expect(found, isEmpty);
    });

    test('when searching by exact email then the user is found', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');

      final found = await endpoints.user.searchUsers(
        anna.endpointSession,
        bo.email,
        10,
      );

      expect(found.map((u) => u.id), [bo.id]);
    });

    test('when calling unauthenticated then getMe is refused', () async {
      await expectLater(
        endpoints.user.getMe(TestUsers.unauthenticated(sessionBuilder)),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });
  });
}
