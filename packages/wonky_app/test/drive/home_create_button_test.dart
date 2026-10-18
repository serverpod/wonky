import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shad/shad.dart' show ShadButton, ShadSpinner;
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import '../board/report/support/report_fakes.dart' show FakeReportBoard;
import '../support/screen_pump.dart';

class ControlledDriveRepository extends FakeDriveRepository {
  ControlledDriveRepository({super.ids});

  Completer<DriveItemView>? createCompleter;
  int createCalls = 0;
  Object? createError;

  @override
  Future<DriveItemView> createDocument({
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
    String? initialMarkdown,
    UuidValue? documentUuid,
    UuidValue? itemUuid,
  }) async {
    createCalls++;
    if (createError != null) {
      throw createError!;
    }
    if (createCompleter != null) {
      return await createCompleter!.future;
    }
    return super.createDocument(
      parentUuid: parentUuid,
      name: name,
      templateUuid: templateUuid,
      initialMarkdown: initialMarkdown,
      documentUuid: documentUuid,
      itemUuid: itemUuid,
    );
  }

  @override
  Future<DriveItemView> createSpreadsheet({
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
  }) async {
    createCalls++;
    if (createError != null) {
      throw createError!;
    }
    if (createCompleter != null) {
      return await createCompleter!.future;
    }
    return super.createSpreadsheet(
      parentUuid: parentUuid,
      name: name,
      templateUuid: templateUuid,
    );
  }

  @override
  Future<DriveItemView> createPresentation({
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
  }) async {
    createCalls++;
    if (createError != null) {
      throw createError!;
    }
    if (createCompleter != null) {
      return await createCompleter!.future;
    }
    return super.createPresentation(
      parentUuid: parentUuid,
      name: name,
      templateUuid: templateUuid,
    );
  }
}

void main() {
  late CommandTestHarness h;
  late ControlledDriveRepository repo;

  CommandTestHarness createHarness({
    WonkyAppKind app = WonkyAppKind.write,
    HomeScope? scope = const HomeScope.kind(DriveItemKind.document),
  }) {
    repo = ControlledDriveRepository();
    final harness = CommandTestHarness(
      config: TestAppConfig(app: app, scope: scope),
      drive: repo,
      board: FakeReportBoard(),
    );
    harness.services.router = GoRouter(
      routes: [
        for (final p in const [
          '/',
          '/my-drive',
          '/my-files',
          '/shared',
          '/starred',
          '/recent',
          '/offline',
          '/trash',
          '/storage',
          '/f/:uuid',
          '/d/:uuid',
          '/s/:uuid',
          '/p/:uuid',
          '/templates',
          '/settings/app',
          '/settings/:section',
        ])
          GoRoute(path: p, builder: (_, _) => const SizedBox()),
      ],
    );
    return harness;
  }

  tearDown(() => h.dispose());

  group('Template strip Blank card creation (T-7)', () {
    testWidgets(
      'tapping Blank card disables button, shows spinner, and ignores rapid clicks',
      (tester) async {
        h = createHarness();
        // Seed an existing item so home is not empty.
        repo.seed(name: 'Existing doc');

        repo.createCompleter = Completer<DriveItemView>();

        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.home(),
          ),
        );

        final blankCard = find.byKey(
          const ValueKey<String>('drive.template.blank'),
        );
        expect(blankCard, findsOneWidget);
        expect(
          find.descendant(of: blankCard, matching: find.byType(ShadSpinner)),
          findsNothing,
        );

        // Tap the create blank document card.
        await tester.tap(blankCard);
        await tester.pump();

        // 1. Immediately shows ShadSpinner and creates exactly 1 call.
        expect(
          find.descendant(of: blankCard, matching: find.byType(ShadSpinner)),
          findsOneWidget,
        );
        expect(h.services.creatingFile.value, isTrue);
        expect(repo.createCalls, 1);

        // 2. Rapid repeated taps do not trigger extra creation calls.
        await tester.tap(blankCard, warnIfMissed: false);
        await tester.pump();
        await tester.tap(blankCard, warnIfMissed: false);
        await tester.pump();
        expect(repo.createCalls, 1);

        // 3. Complete file creation and settle.
        repo.createCompleter!.complete(repo.seed(name: 'Untitled'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(repo.createCalls, 1);
        expect(h.services.creatingFile.value, isFalse);
        expect(
          h.services.router.routeInformationProvider.value.uri.path,
          startsWith('/d/'),
        );
      },
    );

    testWidgets(
      'if creation fails, Blank card re-enables and loading indicator is hidden',
      (tester) async {
        h = createHarness();
        repo.seed(name: 'Existing doc');
        repo.createError = Exception('Failed to create file on server');

        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.home(),
          ),
        );

        final blankCard = find.byKey(
          const ValueKey<String>('drive.template.blank'),
        );
        expect(blankCard, findsOneWidget);

        // Tap to create.
        await tester.tap(blankCard);
        await tester.pump();

        // Failed creation resets state and hides spinner.
        await tester.pumpAndSettle();
        expect(h.services.creatingFile.value, isFalse);
        expect(
          find.descendant(of: blankCard, matching: find.byType(ShadSpinner)),
          findsNothing,
        );

        // Verify button is re-enabled and can be tapped again successfully.
        repo.createError = null;
        await tester.tap(blankCard);
        await tester.pumpAndSettle();

        expect(repo.createCalls, 2);
        expect(
          h.services.router.routeInformationProvider.value.uri.path,
          startsWith('/d/'),
        );
      },
    );

    for (final brightness in Brightness.values) {
      testWidgets(
        'loading indicator renders correctly in ${brightness.name} mode',
        (tester) async {
          h = createHarness();
          repo.seed(name: 'Existing doc');
          repo.createCompleter = Completer<DriveItemView>();

          await pumpScreen(
            tester,
            h,
            DriveHomeScreen(
              services: h.services,
              location: const DriveLocation.home(),
            ),
            brightness: brightness,
          );

          final blankCard = find.byKey(
            const ValueKey<String>('drive.template.blank'),
          );
          await tester.tap(blankCard);
          await tester.pump();

          expect(
            find.descendant(of: blankCard, matching: find.byType(ShadSpinner)),
            findsOneWidget,
          );

          repo.createCompleter!.complete(repo.seed(name: 'Untitled'));
          await tester.pump();
          await tester.pumpAndSettle();
        },
      );
    }
  });

  group('Empty state create button (T-7)', () {
    testWidgets(
      'tapping drive.empty.new disables button and shows spinner until completed',
      (tester) async {
        h = createHarness();
        repo.createCompleter = Completer<DriveItemView>();

        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.myDrive(),
          ),
        );

        final emptyNewBtn = find.byKey(
          const ValueKey<String>('drive.empty.new'),
        );
        expect(emptyNewBtn, findsOneWidget);
        expect(
          find.descendant(of: emptyNewBtn, matching: find.byType(ShadSpinner)),
          findsNothing,
        );

        // Tap empty state create button.
        await tester.tap(emptyNewBtn);
        await tester.pump();

        // 1. Shows spinner and is disabled.
        expect(
          find.descendant(of: emptyNewBtn, matching: find.byType(ShadSpinner)),
          findsOneWidget,
        );
        final disabledBtn = tester.widget<ShadButton>(emptyNewBtn);
        expect(disabledBtn.onPressed, isNull);
        expect(repo.createCalls, 1);

        // 2. Rapid repeated taps do not trigger extra creation calls.
        await tester.tap(emptyNewBtn, warnIfMissed: false);
        await tester.pump();
        await tester.tap(emptyNewBtn, warnIfMissed: false);
        await tester.pump();
        expect(repo.createCalls, 1);

        // 3. Complete creation.
        repo.createCompleter!.complete(repo.seed(name: 'Untitled'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(repo.createCalls, 1);
        expect(h.services.creatingFile.value, isFalse);
      },
    );

    testWidgets(
      'if creation fails, empty state create button re-enables and hides spinner',
      (tester) async {
        h = createHarness();
        repo.createError = Exception('Network error');

        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.myDrive(),
          ),
        );

        final emptyNewBtn = find.byKey(
          const ValueKey<String>('drive.empty.new'),
        );
        expect(emptyNewBtn, findsOneWidget);

        await tester.tap(emptyNewBtn);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(h.services.creatingFile.value, isFalse);
        final reenabledBtn = tester.widget<ShadButton>(emptyNewBtn);
        expect(reenabledBtn.onPressed, isNotNull);
        expect(
          find.descendant(of: emptyNewBtn, matching: find.byType(ShadSpinner)),
          findsNothing,
        );
      },
    );
  });

  group('Drive home New button (T-7)', () {
    testWidgets(
      'HomeNewButton shows spinner and disables when creatingFile is true',
      (tester) async {
        h = createHarness(
          app: WonkyAppKind.drive,
          scope: const HomeScope.all(),
        );

        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.myDrive(),
          ),
        );

        final driveNewBtn = find.byKey(const ValueKey<String>('drive.new'));
        expect(driveNewBtn, findsOneWidget);
        expect(
          find.descendant(of: driveNewBtn, matching: find.byType(ShadSpinner)),
          findsNothing,
        );

        // Simulate file creation in progress.
        h.services.creatingFile.value = true;
        await tester.pump();

        expect(
          find.descendant(of: driveNewBtn, matching: find.byType(ShadSpinner)),
          findsOneWidget,
        );
        final disabledBtn = tester.widget<ShadButton>(driveNewBtn);
        expect(disabledBtn.onPressed, isNull);

        // Creation finished.
        h.services.creatingFile.value = false;
        await tester.pump();

        expect(
          find.descendant(of: driveNewBtn, matching: find.byType(ShadSpinner)),
          findsNothing,
        );
        final activeBtn = tester.widget<ShadButton>(driveNewBtn);
        expect(activeBtn.onPressed, isNotNull);
      },
    );
  });
}
