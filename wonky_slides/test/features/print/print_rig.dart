import 'package:flutter/foundation.dart';
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
import 'package:wonky_slides/features/print/print_controller.dart';
import 'package:wonky_slides/features/print/print_preview_screen.dart';
import 'package:wonky_slides/features/print/slides_client_export.dart';
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_sync_models/ids.dart' show SequentialIdGenerator;
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyThemeConfig;

import '../../support/deck_screen.dart' show sampleDeck;
import '../../support/slides_harness.dart';

/// The print preview route over the deck editor (as `editorRoutes` mounts
/// it), rendering real PDFs with the core TTF layout.
class PrintRig {
  PrintRig(this.h, this.session);

  final CommandTestHarness h;
  final MemoryDeckSession session;

  ShellServices get services => h.services;

  DeckEditorController get editor =>
      (services.activeDocument.value! as DeckDocumentController).editor!;

  SlidesPrintController get controller => activeSlidesPrint.value!.controller!;

  String get location =>
      services.router.routeInformationProvider.value.uri.toString();

  /// Lets real async work (asset loads, PDF writing) and fake timers run
  /// until [done] (or a bounded number of rounds).
  Future<void> settle(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 400 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump();
  }

  /// Waits for the first PDF.
  Future<void> rendered(WidgetTester tester) => settle(tester, () {
    final c = activeSlidesPrint.value?.controller;
    return c != null && !c.busy && (c.pdf != null || c.error != null);
  });

  /// Replaces the file saver; returns the restore function.
  void Function() saveWith(
    Future<bool> Function(Uint8List bytes, String fileName) saver,
  ) {
    final previous = SlidesClientExport.saver;
    SlidesClientExport.saver = saver;
    return () => SlidesClientExport.saver = previous;
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    await h.dispose();
  }
}

/// Pumps the print preview for [fixture] (default: the four-slide sample
/// deck with one skipped slide) as [role].
Future<PrintRig> pumpPrintPreview(
  WidgetTester tester, {
  DeckBuilder? fixture,
  AccessRole role = AccessRole.owner,
  bool nonEditorsCanExport = true,
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
    role: role,
    nonEditorsCanExport: nonEditorsCanExport,
  );
  final session = MemoryDeckSession(
    itemUuid: uuid,
    userId: b.userId,
    model: b.build(),
    planner: const SlidesPlanner(),
    role: role == AccessRole.owner ? Role.owner : Role.viewer,
    ids: SequentialIdGenerator(10000),
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final l = slidesL10nEnglish;
  final fonts = SlidesClientExport.assetFonts();
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
            // Covered by the opaque print route (not painted), as under
            // the router's page stack.
            Offstage(
              child: DeckEditorScreen(
                services: h.services,
                itemUuid: uuid.uuid,
                sessionFactory: (services, item) async => session,
              ),
            ),
            Positioned.fill(
              child: PrintPreviewScreen(
                services: h.services,
                itemUuid: uuid.uuid,
                renderer: (deck, o, cancelled) => SlidesClientExport.render(
                  deck,
                  o,
                  images: session.images,
                  l: l,
                  screenLayout: false,
                  // Per test: cached futures don't cross fake-async zones.
                  fonts: fonts,
                  isCancelled: cancelled,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  final rig = PrintRig(h, session);
  await rig.rendered(tester);
  return rig;
}
