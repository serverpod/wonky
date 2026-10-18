import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/features/editor_screen/deck_document_controller.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_screen.dart';
import 'package:wonky_slides/features/model/memory_deck_session.dart';
import 'package:wonky_slides/features/present/active_presentation.dart';
import 'package:wonky_slides/features/present/present_controller.dart';
import 'package:wonky_slides/features/present/present_screen.dart';
import 'package:wonky_slides/features/present/presentation_link.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_sync_models/ids.dart' show SequentialIdGenerator;
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyThemeConfig;

import '../../support/deck_screen.dart' show sampleDeck;
import '../../support/slides_harness.dart';

/// The present route over the deck editor (as `editorRoutes` mounts it)
/// with a test clock (the 120 ms burst filter) and an optional fake
/// session transport.
class PresentRig {
  PresentRig(this.h, this.session, this.fixture, this.clock);

  final CommandTestHarness h;
  final MemoryDeckSession session;
  final DeckBuilder fixture;
  final List<int> clock;

  ShellServices get services => h.services;

  DeckEditorController get editor =>
      (services.activeDocument.value! as DeckDocumentController).editor!;

  PresentController get controller => activePresentation.value!.controller!;

  /// Slide ids in deck order.
  List<String> get ids => [for (final e in editor.order.entries) e.id];

  String? get shown => controller.position?.slideId;

  String get location =>
      services.router.routeInformationProvider.value.uri.toString();

  String get deckPath => '/p/${session.itemUuid.uuid}';

  bool get isMac => services.keymap.platform.isMac;

  /// Presses [key] (with modifiers) 200 ms after the last input.
  Future<void> press(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool shift = false,
    bool mod = false,
  }) async {
    clock[0] += 200;
    final modKey = isMac
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    if (mod) await tester.sendKeyDownEvent(modKey);
    await tester.sendKeyEvent(key);
    if (mod) await tester.sendKeyUpEvent(modKey);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
  }

  /// Runs real async work (streams of the fake transport) and pumps.
  Future<void> settle(WidgetTester tester, [int rounds = 6]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    debugPresentationTransport = null;
    await h.dispose();
  }
}

/// Pumps the present screen in [view] for [fixture] (default: the sample
/// deck — title, group "Intro" with a noted slide and a skipped slide, and
/// "Demo").
Future<PresentRig> pumpPresent(
  WidgetTester tester, {
  PresentView view = PresentView.present,
  DeckBuilder? fixture,
  DeckModel? model,
  bool kiosk = false,
  String? startSlideId,
  String? sessionId,
  PresentationTransport? transport,
  Brightness brightness = Brightness.light,
  Size size = const Size(1440, 900),
}) async {
  final h = slidesHarness();
  final b = fixture ?? sampleDeck();
  final uuid = UuidValue.fromString(b.deckId);
  h.drive.seed(
    name: b.title,
    uuid: uuid,
    kind: DriveItemKind.presentation,
    role: AccessRole.owner,
  );
  final session = MemoryDeckSession(
    itemUuid: uuid,
    userId: b.userId,
    model: model ?? b.build(),
    planner: const SlidesPlanner(),
    role: Role.owner,
    ids: SequentialIdGenerator(10000),
  );
  debugPresentationTransport = transport;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final clock = [1000000];
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: h.services,
      child: WonkyTestApp(
        brightness: brightness,
        config: const WonkyThemeConfig(),
        locale: const Locale('en'),
        extraDelegates: [
          WonkyAppLocalizations.delegate,
          ...h.services.config.localizationsDelegates,
        ],
        child: Stack(
          children: [
            Offstage(
              child: DeckEditorScreen(
                services: h.services,
                itemUuid: uuid.uuid,
                sessionFactory: (services, item) async => session,
              ),
            ),
            Positioned.fill(
              child: PresentScreen(
                services: h.services,
                itemUuid: uuid.uuid,
                view: view,
                startSlideId: startSlideId,
                sessionId: sessionId,
                kiosk: kiosk,
                nowMs: () => clock[0],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  final rig = PresentRig(h, session, b, clock);
  for (var i = 0; i < 8 && activePresentation.value?.controller == null; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await rig.settle(tester, 3);
  return rig;
}
