@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope, UiSlidesTools;
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/mcp/ui_bridge/ui_bridge_hub.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// A fake app window of [app] on `uiBridge.connect`.
class _Window {
  _Window(this.input, this.queue);

  final StreamController<UiBridgeMessage> input;
  final StreamQueue<UiBridgeMessage> queue;
  late String sessionId;

  static Future<_Window> connect(
    TestEndpoints endpoints,
    TestUser user, {
    required String app,
    List<String> tools = const [],
  }) async {
    final input = StreamController<UiBridgeMessage>();
    final w = _Window(
      input,
      StreamQueue(
        endpoints.uiBridge.connect(user.endpointSession, input.stream),
      ),
    );
    input.add(
      UiBridgeHello(
        app: app,
        deviceLabel: 'Test browser',
        platform: 'web',
        route: '/',
        focused: true,
        tools: tools,
      ),
    );
    final welcome = await w.queue.next.timeout(const Duration(seconds: 5));
    w.sessionId = (welcome as UiBridgeWelcome).sessionId;
    return w;
  }

  Future<UiBridgeRequest> nextRequest() async {
    while (true) {
      final m = await queue.next.timeout(const Duration(seconds: 5));
      if (m is UiBridgeRequest) return m;
    }
  }

  void respond(UiBridgeRequest r, Object? result, {String? image}) => input.add(
    UiBridgeResponse(
      requestId: r.requestId,
      ok: true,
      resultJson: jsonEncode(result),
      text: 'done',
      imageBase64: image,
    ),
  );

  Future<void> close() async {
    await input.close();
    await queue.cancel(immediate: true);
  }
}

/// `ui.slides.*` (Slides 11 §5; SL-42) are relayed to the user's Wonky
/// Slides windows like `ui.drive.*` to Drive's: other apps' windows don't
/// get them, the window's result (and screenshot image) comes back, and
/// tokens without `ui:control` can't call them.
void main() {
  withWonkyServerpod('Given the UI bridge and Slides tools', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    setUp(() async {
      UiBridgeHub.clear();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
    });

    test('when no Slides window is connected then ui.slides calls answer '
        'no_session', () async {
      final write = await _Window.connect(endpoints, anna, app: 'write');

      final e = await mcp.error('ui.slides.get_selection');

      expect(e['code'], 'no_session');
      await write.close();
    });

    test('when a Slides window is open then go_to_slide reaches it with the '
        'arguments and its result returns', () async {
      final w = await _Window.connect(
        endpoints,
        anna,
        app: 'slides',
        tools: [for (final t in UiSlidesTools.all) t.name],
      );

      final pending = mcp.call('ui.slides.go_to_slide', {'slide': 3});
      final req = await w.nextRequest();
      w.respond(req, {
        'current_slide': {'slide_id': 's3', 'position': 3},
      });
      final r = await pending;

      expect(req.tool, 'ui.slides.go_to_slide');
      expect(jsonDecode(req.argsJson), {'slide': 3});
      expect(r['session_id'], w.sessionId);
      expect(r['current_slide'], containsPair('position', 3));
      await w.close();
    });

    test('when a slide is screenshot then the PNG comes back as image '
        'content', () async {
      final w = await _Window.connect(
        endpoints,
        anna,
        app: 'slides',
        tools: const ['ui.slides.screenshot_slide'],
      );

      final pending = mcp.call('ui.slides.screenshot_slide', {'scale': 0.5});
      final req = await w.nextRequest();
      w.respond(req, {'width': 960, 'height': 540}, image: 'iVBORw0KGgo=');
      final r = await pending;

      expect(req.tool, 'ui.slides.screenshot_slide');
      expect(r['width'], 960);
      await w.close();
    });

    test('when the arguments break the schema then the window is not '
        'asked', () async {
      final w = await _Window.connect(endpoints, anna, app: 'slides');

      final e = await mcp.error('ui.slides.present_control', {
        'action': 'rewind',
      });

      expect(e['code'], 'invalid_args');
      await w.close();
    });

    test(
      'when the token lacks ui:control then the call is forbidden',
      () async {
        final readOnly = await McpHarness.forUser(
          anna,
          scopes: const [McpScope.slidesRead],
        );
        final w = await _Window.connect(endpoints, anna, app: 'slides');

        final e = await readOnly.error('ui.slides.get_view');

        expect(e['code'], 'forbidden');
        await w.close();
      },
    );
  });
}
