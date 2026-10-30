import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write/commands/theme_commands.dart';
import 'package:wonky_write/features/theme_editor/theme_editor_controller.dart';
import 'package:wonky_write/features/theme_editor/theme_editor_screen.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import 'support/fake_theme_repository.dart';

void main() {
  late CommandTestHarness h;
  late FakeThemeRepository repo;
  late WriteThemeCatalog catalog;

  setUp(() {
    h = CommandTestHarness();
    repo = FakeThemeRepository(me: TestUsers.anna.uuid.uuid);
    setThemeRepository(h.services, repo);
    catalog = WriteThemeCatalog(
      fetch: (uuid, {viaDocumentUuid}) async =>
          ThemeOption.fromRecord(await repo.get(uuid)),
      fetchMine: () async => [
        for (final r in await repo.listMine()) ?ThemeOption.fromRecord(r),
      ],
    );
    h.services.registry.registerAll(themeCommands(h.services, catalog));
  });
  tearDown(() async {
    ThemeEditorController.active.value = null;
    await h.dispose();
  });

  Future<void> pumpEditor(
    WidgetTester tester,
    String uuid, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1440, 900),
  }) async {
    h.services.router = GoRouter(
      initialLocation: '/themes/$uuid',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/themes/:id',
          builder: (_, state) => ThemeEditorScreen(
            key: ValueKey(state.pathParameters['id']),
            services: h.services,
            themes: catalog,
            themeUuid: state.pathParameters['id']!,
          ),
        ),
      ],
    );
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      Provider<ShellServices>.value(
        value: h.services,
        child: ShadApp.router(
          theme: WonkyTheme.light(),
          darkTheme: WonkyTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ShadThemeMode.dark
              : ShadThemeMode.light,
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
  }

  ThemeEditorController editor() => ThemeEditorController.active.value!;

  for (final b in Brightness.values) {
    testWidgets('Given my theme in ${b.name} when the editor opens then the '
        'tree, preview and inspector show', (tester) async {
      final mine = repo.seed(name: 'Report');
      await pumpEditor(tester, mine.uuid, brightness: b);

      expect(
        find.byKey(const ValueKey('write.themeEditor.name')),
        findsOneWidget,
      );
      expect(find.text('Report'), findsWidgets);
      expect(
        find.byKey(const ValueKey('write.themeEditor.preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('write.themeEditor.node.h2')),
        findsOneWidget,
      );
      expect(find.text('Body text'), findsWidgets);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
    });
  }

  testWidgets('Given my theme when selecting Heading 2 and changing its size '
      'then the draft is unsaved and Save stores it', (tester) async {
    final mine = repo.seed(name: 'Report');
    await pumpEditor(tester, mine.uuid);

    await tester.tap(find.byKey(const ValueKey('write.themeEditor.node.h2')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('write.themeEditor.inspector.title')),
          )
          .data,
      'Heading 2',
    );
    expect(
      find.byKey(const ValueKey('write.themeEditor.prop.elements.h2.fontSize')),
      findsOneWidget,
    );

    await h.invoke('write.theme.setProperty', {
      'path': 'elements.h2.fontSize',
      'value': '22pt',
    }, InvocationSource.ui);
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('write.themeEditor.save')));
    await tester.pumpAndSettle();

    final saved = jsonDecode(repo.themes[mine.uuid]!.json) as Map;
    expect((saved['elements'] as Map)['h2'], {'fontSize': '22pt'});
    expect(find.text('All changes saved'), findsOneWidget);
    await settleTooltips(tester);
  });

  testWidgets('Given my theme when undoing a draft change with the toolbar '
      'then the change is gone', (tester) async {
    final mine = repo.seed(name: 'Report');
    await pumpEditor(tester, mine.uuid);
    await h.invoke('write.theme.setProperty', {
      'path': 'palette.accent',
      'value': '#ff0000',
    }, InvocationSource.ui);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('write.themeEditor.undo')));
    await tester.pumpAndSettle();

    expect(editor().dirty, isFalse);
    await settleTooltips(tester);
  });

  testWidgets('Given a built-in theme when opened then the inspector is '
      'read-only and Duplicate opens the copy', (tester) async {
    await pumpEditor(tester, BuiltinThemes.wonkyDefault.uuid);

    expect(
      find.byKey(const ValueKey('write.themeEditor.readOnly')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('write.themeEditor.save')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('write.themeEditor.duplicate')));
    await tester.pumpAndSettle();

    final copy = repo.themes.values.single;
    expect(copy.name, 'Wonky Default (copy)');
    expect(
      h.services.router.routeInformationProvider.value.uri.path,
      '/themes/${copy.uuid}',
    );
    expect(editor().themeUuid, copy.uuid);
    expect(editor().readOnly, isFalse);
    await settleTooltips(tester);
  });

  testWidgets('Given a low-contrast body color when viewing Body text then '
      'a warning offers Fix', (tester) async {
    final mine = repo.seed(name: 'Report');
    await pumpEditor(tester, mine.uuid);
    await h.invoke('write.theme.setProperty', {
      'path': 'palette.text',
      'value': '#dddddd',
    }, InvocationSource.ui);
    await tester.pumpAndSettle();

    final warning = find.byKey(
      const ValueKey('write.themeEditor.contrast.body.light'),
    );
    expect(warning, findsOneWidget);
    await tester.tap(find.descendant(of: warning, matching: find.text('Fix')));
    await tester.pumpAndSettle();

    expect(warning, findsNothing);
    await settleTooltips(tester);
  });

  testWidgets('Given Theme colors when opening a color then a compact picker '
      'opens and choosing a theme swatch stores a palette reference', (
    tester,
  ) async {
    final mine = repo.seed(name: 'Report');
    await pumpEditor(tester, mine.uuid);
    await tester.tap(
      find.byKey(const ValueKey('write.themeEditor.node.palette')),
    );
    await tester.pumpAndSettle();

    final link = find.byKey(
      const ValueKey('write.themeEditor.palette.linkHover'),
    );
    await tester.tap(
      find.descendant(of: link, matching: find.byType(ShadButton)).first,
    );
    await tester.pumpAndSettle();

    final picker = find.byType(WonkyColorPicker);
    expect(picker, findsOneWidget);
    expect(tester.getSize(picker).width, lessThan(320));
    await tester.tap(
      find.descendant(of: picker, matching: find.bySemanticsLabel('Accent')),
    );
    await tester.pumpAndSettle();

    expect(
      ThemePropertyPath.get(editor().draftJson, 'palette.linkHover'),
      '@accent',
    );
    await settleTooltips(tester);
  });

  testWidgets('Given a narrow window when the editor opens then the panels '
      'become tabs without overflow', (tester) async {
    final mine = repo.seed(name: 'Report');
    await pumpEditor(tester, mine.uuid, size: const Size(800, 900));

    expect(find.text('Properties'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
  });
}
