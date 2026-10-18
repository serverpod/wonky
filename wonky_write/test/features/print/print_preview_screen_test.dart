import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write/features/print/print_preview_screen.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show ThemeVariant;

import '../screen/support/shad_fonts.dart';

const _uuid = '00000000-0000-7000-8000-0000000000a1';
const _documentPage = ValueKey<String>('test.documentPage');
const _download = ValueKey<String>('print.download');
const _print = ValueKey<String>('print.print');
const _headerFooter = ValueKey<String>('print.headerFooter');
const _toc = ValueKey<String>('print.toc');

/// The shell without a server connection (`ShellServices.client` is null,
/// as offline and in widget tests), routed at `/d/<uuid>/print`.
Future<CommandTestHarness> _pumpPreview(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
}) async {
  final h = CommandTestHarness();
  addTearDown(h.dispose);
  h.services.router = GoRouter(
    initialLocation: '/d/$_uuid/print',
    routes: [
      GoRoute(
        path: '/d/:id',
        builder: (_, _) => const Text('Document', key: _documentPage),
        routes: [
          GoRoute(
            path: 'print',
            builder: (_, state) => PrintPreviewScreen(
              services: h.services,
              itemUuid: state.pathParameters['id']!,
              themes: WriteThemeCatalog(),
            ),
          ),
        ],
      ),
    ],
  );
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: h.services,
      child: ShadApp.router(
        theme: WonkyTheme.light(),
        darkTheme: WonkyTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        routerConfig: h.services.router,
        localizationsDelegates: const [
          WonkyAppLocalizations.delegate,
          WonkyUiLocalizations.delegate,
        ],
        builder: (context, child) =>
            WonkyThemeScope(data: const WonkyThemeExtension(), child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  return h;
}

bool _enabled(WidgetTester tester, Key key) =>
    tester.widget<ShadButton>(find.byKey(key)).enabled;

bool _checked(WidgetTester tester, Key key) =>
    tester.widget<ShadCheckbox>(find.byKey(key)).value;

String _location(CommandTestHarness h) =>
    h.services.router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUpAll(loadShadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('Given no server connection (${brightness.name}) when the '
        'print preview opens then it explains the failure and Download and '
        'Print are disabled', (tester) async {
      await _pumpPreview(tester, brightness: brightness);

      expect(find.text('Print preview'), findsOneWidget);
      expect(find.text('The preview could not be created'), findsOneWidget);
      expect(find.text('No server connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(_enabled(tester, _download), isFalse);
      expect(_enabled(tester, _print), isFalse);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byKey(const ValueKey('print.pages')), findsNothing);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  }

  group('Given the print preview without a server connection', () {
    testWidgets('when pressing Back then the document opens again', (
      tester,
    ) async {
      final h = await _pumpPreview(tester);

      await tester.tap(find.byKey(const ValueKey('print.back')));
      await tester.pumpAndSettle();

      expect(_location(h), '/d/$_uuid');
      expect(find.byKey(_documentPage), findsOneWidget);
    });

    testWidgets('when pressing Escape then the document opens again', (
      tester,
    ) async {
      final h = await _pumpPreview(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_location(h), '/d/$_uuid');
    });

    testWidgets('when pressing Try again then it retries and fails the same '
        'way', (tester) async {
      await _pumpPreview(tester);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('No server connection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('when pressing Ctrl+P before a PDF exists then nothing is '
        'printed and no toast shows', (tester) async {
      final h = await _pumpPreview(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(find.text('Printing isn’t available here'), findsNothing);
      expect(_location(h), '/d/$_uuid/print');
    });

    testWidgets('when toggling the header, footer and table of contents then '
        'the settings show the new values', (tester) async {
      await _pumpPreview(tester);
      expect(_checked(tester, _headerFooter), isTrue);
      expect(_checked(tester, _toc), isFalse);

      await tester.tap(find.byKey(_headerFooter));
      await tester.pump();
      await tester.tap(find.byKey(_toc));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(_checked(tester, _headerFooter), isFalse);
      expect(_checked(tester, _toc), isTrue);
      expect(find.text('No server connection'), findsOneWidget);
    });

    testWidgets('when choosing dark colors then the Dark option is '
        'selected', (tester) async {
      await _pumpPreview(tester);

      await tester.tap(find.byKey(const ValueKey('print.dark')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
        tester
            .state<ShadRadioGroupState<ThemeVariant>>(
              find.byType(ShadRadioGroup<ThemeVariant>),
            )
            .effectiveController
            .value,
        ThemeVariant.dark,
      );
    });
  });
}
