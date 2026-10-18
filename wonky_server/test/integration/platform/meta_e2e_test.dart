@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/e2e/e2e_codes.dart';
import 'package:wonky_server/src/platform/e2e/e2e_support_endpoint.dart';

import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given the meta endpoint', (sessionBuilder, endpoints) {
    test(
      'when getting info unauthenticated then versions, flags and the schema hashes are returned',
      () async {
        final info = await endpoints.meta.getInfo(
          TestUsers.unauthenticated(sessionBuilder),
        );

        expect(info.minClientVersion, isNotEmpty);
        expect(info.revSchemaHash, startsWith('sheets:'));
        expect(info.runMode, ServerpodRunMode.test);
        expect(info.limits.maxDocumentChars, 2000000);
        // Tests run without Redis.
        expect(info.redisEnabled, isFalse);
        expect(info.redisConnected, isFalse);
      },
    );
  });

  withWonkyServerpod('Given the e2e support endpoint in test mode', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when a code was recorded for an example.test address then it is returned',
      () async {
        E2eCodes.recordRegistration('e2e+1-anna@example.test', '123456');

        final code = await endpoints.e2eSupport.latestVerificationCode(
          sessionBuilder,
          'e2e+1-anna@example.test',
        );

        expect(code, '123456');
      },
    );

    test('when asking for a real address then it is refused', () async {
      await expectLater(
        endpoints.e2eSupport.latestVerificationCode(
          sessionBuilder,
          'anna@gmail.com',
        ),
        throwsA(isA<WonkyException>()),
      );
    });
  });

  for (final mode in [ServerpodRunMode.production, ServerpodRunMode.staging]) {
    test(
      'Given run mode $mode when asking the e2e endpoint for a code then it is refused',
      () {
        expect(
          () => E2eSupportEndpoint.check(mode, 'a@example.test'),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.unavailable,
            ),
          ),
        );
      },
    );
  }
}
