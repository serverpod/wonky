import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/src/settings/sections/other_sections.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import '../support/screen_pump.dart';

class _Meta implements MetaRepository {
  _Meta(this.info);

  ProtocolInfo info;

  @override
  Future<ProtocolInfo> getInfo() async => info;

  @override
  Future<void> submitFeedback(FeedbackSubmission submission) async {}
}

ProtocolInfo _info({required bool enabled, bool connected = false}) =>
    ProtocolInfo(
      serverVersion: '1',
      minClientVersion: '1',
      revSchemaHash: '',
      runMode: 'development',
      features: FeatureFlags(
        ai: false,
        scripting: false,
        mcpUiBridge: false,
        experimentalCharts: false,
      ),
      limits: ServerLimits(
        maxCellsPerSpreadsheet: 1,
        maxSheetsPerSpreadsheet: 1,
        maxDocumentChars: 1,
        maxImageUploadBytes: 1,
        maxImportUploadBytes: 1,
        scriptTimeoutMs: 1,
      ),
      serverTime: DateTime.utc(2026),
      redisEnabled: enabled,
      redisConnected: connected,
    );

void main() {
  for (final (enabled, connected, text) in const [
    (true, true, 'Connected'),
    (true, false, 'Not reachable'),
    (false, false, 'Not configured'),
  ]) {
    testWidgets(
      'Given Redis ${enabled ? (connected ? 'connected' : 'down') : 'off'} '
      'when Settings › Developer shows then the Redis row says "$text"',
      (tester) async {
        final h = CommandTestHarness(
          meta: _Meta(_info(enabled: enabled, connected: connected)),
        );
        addTearDown(h.dispose);
        await pumpScreen(
          tester,
          h,
          SingleChildScrollView(child: ServerStatusGroup(services: h.services)),
        );

        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey<String>('settings.server.redis')),
              )
              .data,
          text,
        );
      },
    );
  }
}
