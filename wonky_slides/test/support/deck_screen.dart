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
import 'package:wonky_slides/features/model/deck_session.dart';
import 'package:wonky_slides/features/model/memory_deck_session.dart';
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_sync_models/ids.dart' show SequentialIdGenerator;
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyThemeConfig;

import 'slides_harness.dart';

/// A four-slide deck: a title slide, a group "Intro" (blue) with two slides
/// (the second skipped, the first with notes) and a top-level slide.
DeckBuilder sampleDeck() {
  final b = DeckBuilder(title: 'Q3 review');
  b.slide(layoutKey: 'title', title: 'Q3 review');
  final intro = b.group('Intro', color: 'blue');
  b.slide(
    groupId: intro,
    title: 'Our mission',
    body: 'Make collaboration effortless',
    notes: 'Say hello first',
  );
  b.slide(groupId: intro, title: 'The problem', skipped: true);
  b.slide(title: 'Demo');
  return b;
}

/// A deck session whose load state tests drive (downloading, unavailable).
class ScriptedDeckSession extends MemoryDeckSession {
  ScriptedDeckSession({
    required super.itemUuid,
    required super.userId,
    required super.model,
    required super.planner,
    super.role,
    DeckLoadState initial = const DeckLoading(),
  }) {
    loadStateNotifier.value = initial;
  }

  set state(DeckLoadState s) => loadStateNotifier.value = s;
}

/// The deck editor screen pumped with a memory session (Slides 04 §2).
class DeckScreenRig {
  DeckScreenRig(this.h, this.session, this.fixture);

  final CommandTestHarness h;
  final MemoryDeckSession session;
  final DeckBuilder fixture;

  ShellServices get services => h.services;

  DeckDocumentController get doc =>
      services.activeDocument.value! as DeckDocumentController;

  DeckEditorController get editor => doc.editor!;

  /// Invokes a command as the UI does.
  Future<CommandResult> run(
    String id, [
    Map<String, Object?> args = const {},
  ]) => h.invoke(id, args, InvocationSource.ui);

  /// Ends the test without pending timers (the screen disposes after the
  /// frame).
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    await h.dispose();
  }
}

/// Pumps `DeckEditorScreen` for [fixture] (default [sampleDeck]) as
/// [role]; [scripted] keeps the session in the given load state.
Future<DeckScreenRig> pumpDeckScreen(
  WidgetTester tester, {
  DeckBuilder? fixture,
  AccessRole role = AccessRole.owner,
  Brightness brightness = Brightness.light,
  Size size = const Size(1440, 900),
  DeckLoadState? scripted,
  DeckSessionFactory? factory,
  String? initialSlideId,
  PresenceRepository? presence,
  void Function(CommandTestHarness h)? beforePump,
}) async {
  final h = slidesHarness(presence: presence);
  beforePump?.call(h);
  final b = fixture ?? sampleDeck();
  final uuid = UuidValue.fromString(b.deckId);
  h.drive.seed(
    name: b.title,
    uuid: uuid,
    kind: DriveItemKind.presentation,
    role: role,
  );
  final sessionRole = switch (role) {
    AccessRole.owner => Role.owner,
    AccessRole.editor => Role.editor,
    AccessRole.commenter => Role.commenter,
    _ => Role.viewer,
  };
  final MemoryDeckSession session = scripted == null
      ? MemoryDeckSession(
          itemUuid: uuid,
          userId: b.userId,
          model: b.build(),
          planner: const SlidesPlanner(),
          role: sessionRole,
          ids: SequentialIdGenerator(10000),
        )
      : ScriptedDeckSession(
          itemUuid: uuid,
          userId: b.userId,
          model: b.build(),
          planner: const SlidesPlanner(),
          role: sessionRole,
          initial: scripted,
        );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // The services sit above the app so that dialogs (their own routes)
  // register with them (`openDialogs`, MCP `ui.get_dialog`).
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
        child: DeckEditorScreen(
          services: h.services,
          itemUuid: uuid.uuid,
          initialSlideId: initialSlideId,
          sessionFactory: factory ?? (services, item) async => session,
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
  return DeckScreenRig(h, session, b);
}
