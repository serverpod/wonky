import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/config/wonky_config.dart';
import 'package:wonky_server/src/platform/config/wonky_config_file.dart';

/// `WonkyConfigFile` (CQ-33): one loader for every `wonky:` section.
void main() {
  late Directory dir;
  setUp(() {
    WonkyConfigFile.clear();
    dir = Directory.systemTemp.createTempSync('wonky_config_');
    Directory('${dir.path}/config').createSync();
    File('${dir.path}/config/staging.yaml').writeAsStringSync('''
wonky:
  features:
    ai: false
  mcp:
    rateLimitPerMinute: 42
''');
  });
  tearDown(() {
    WonkyConfigFile.clear();
    dir.deleteSync(recursive: true);
  });

  group('Given a config file', () {
    test('when a section is read then its map is returned', () {
      final mcp = WonkyConfigFile.section(
        'mcp',
        runMode: 'staging',
        directory: dir,
      );

      expect(mcp['rateLimitPerMinute'], 42);
    });

    test('when a missing section is read then it is empty', () {
      expect(
        WonkyConfigFile.section('board', runMode: 'staging', directory: dir),
        isEmpty,
      );
    });

    test('when the run mode has no file then the configuration is empty', () {
      expect(
        WonkyConfigFile.wonky(runMode: 'production', directory: dir),
        isEmpty,
      );
    });

    test('when WonkyConfig loads the file then it reads the same section', () {
      final config = WonkyConfig.load('staging', directory: dir);

      expect(config.aiEnabled, isFalse);
    });

    test('when the run mode is unknown then loading fails loudly', () {
      expect(
        () => WonkyConfigFile.section('mcp', runMode: 'stagin', directory: dir),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('stagin'),
          ),
        ),
      );
    });
  });
}
