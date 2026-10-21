import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write/commands/screen_commands.dart';
import 'package:wonky_write/features/screen/write_document_controller.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../../document/support/session_harness.dart';
import '../../sync/support/fake_document_server.dart';

/// A loaded document (in-process OT server) with the Write commands
/// registered and a [WriteDocumentController] active, for screen tests.
class ScreenHarness {
  ScreenHarness._(this.server, this.session, this.doc);

  static Future<ScreenHarness> open(
    WidgetTester tester, {
    String markdown = 'Hello\n',
  }) async {
    final server = FakeDocumentServer(
      initial: const MarkdownCodec().importMarkdown(markdown).delta,
    );
    final h = SessionHarness(server);
    await tester.runAsync(() => h.open());
    final catalog = WriteThemeCatalog();
    h.services.registry.registerAll(writeCommands(h.services, catalog));
    final doc = WriteDocumentController(
      services: h.services,
      session: h.session,
      themes: catalog,
    );
    h.services.activate(doc);
    return ScreenHarness._(server, h, doc);
  }

  final FakeDocumentServer server;
  final SessionHarness session;
  final WriteDocumentController doc;

  ShellServices get services => session.services;

  /// Commands invoked through the dispatcher, in order.
  final List<String> invoked = [];

  /// Pumps [child] inside a shad app with the shell services provided.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    services.dispatcher.events.listen((e) => invoked.add(e.id.value));
    await tester.pumpWidget(
      Provider<ShellServices>.value(
        value: services,
        child: ShadApp(
          theme: brightness == Brightness.dark
              ? WonkyTheme.dark()
              : WonkyTheme.light(),
          localizationsDelegates: const [
            WonkyAppLocalizations.delegate,
            WonkyUiLocalizations.delegate,
          ],
          home: Material(
            type: MaterialType.transparency,
            child: WonkyThemeScope(
              data: const WonkyThemeExtension(),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> dispose(WidgetTester tester) async {
    services.deactivate(doc);
    doc.dispose();
    await tester.runAsync(session.dispose);
  }
}
