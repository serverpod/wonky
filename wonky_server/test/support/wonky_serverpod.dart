import 'package:meta/meta.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/server.dart' show registerVersionProviders;
import 'package:wonky_server/src/platform/revlog/rev_storage.dart';
import 'package:wonky_server/src/slides/revlog/slides_revlog.dart';
import 'package:wonky_server/src/write/ot/document_cache.dart';
import 'package:wonky_server/src/write/themes/theme_service.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

export '../integration/test_tools/serverpod_test_tools.dart';

/// [withServerpod] with the Wonky runtime pieces the server installs at
/// start: version providers, database cloud storage and the
/// built-in themes.
///
/// The database is not rolled back between tests (RevLog and OT code
/// run their own transactions); tests stay isolated by using fresh users.
@isTestGroup
void withWonkyServerpod(
  String testGroupName,
  TestClosure<TestEndpoints> testClosure, {
  String? runMode,
}) {
  withServerpod(
    testGroupName,
    (sessionBuilder, endpoints) {
      setUpAll(() async {
        final session = sessionBuilder.build();
        final pod = session.serverpod;
        if (pod.storage['private'] == null) {
          pod.addCloudStorage(DatabaseCloudStorage('private'));
        }
        if (pod.storage['public'] == null) {
          pod.addCloudStorage(DatabaseCloudStorage('public'));
        }
        registerVersionProviders();
        SlidesRevlog.register();
        await ThemeService.upsertBuiltins(session);
        await RevStorage.ensure(session);
      });
      tearDownAll(DocumentCache.clear);
      testClosure(sessionBuilder, endpoints);
    },
    rollbackDatabase: RollbackDatabase.disabled,
    runMode: runMode,
  );
}
