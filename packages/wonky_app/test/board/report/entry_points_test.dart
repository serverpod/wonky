import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/src/auth/screens/sign_in_screen.dart';
import 'package:wonky_app/src/board/report/board_report_dialog.dart';
import 'package:wonky_app/src/board/report/report_draft.dart';
import 'package:wonky_app/src/settings/sections/other_sections.dart';
import 'package:wonky_app/src/shell/overlays/shell_overlays.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import '../../support/screen_pump.dart' show expectAccessible;
import 'support/report_fakes.dart';

/// The entry points of Bugs & improvements that replaced *Report a bug*
/// (specs/16 §4.1). The Help menu is covered in
/// `commands/shell_commands/shell_v2_commands_test.dart`, the left menu in
/// `drive/scoped_home_test.dart`.
void main() {
  late CommandTestHarness h;
  late FakeReportBoard board;

  setUp(() {
    board = FakeReportBoard();
    h = reportHarness(board: board);
  });
  tearDown(() => h.dispose());

  BoardReportDialogState dialog(WidgetTester tester) =>
      tester.state<BoardReportDialogState>(find.byType(BoardReportDialog));

  testWidgets('Given the sign-in screen when the Bugs & improvements link is '
      'used then the board page opens (no dialog)', (tester) async {
    await h.dispose();
    h = reportHarness(board: board, auth: FakeAuthRepository(signedIn: false));
    await pumpReportShell(tester, h, SignInScreen(services: h.services));

    expect(key('auth.reportBug'), findsNothing);
    await tester.ensureVisible(key('auth.board'));
    await tester.tap(key('auth.board'));
    await tester.pumpAndSettle();

    expect(routerPath(h), '/improvements');
    expect(key(BoardReportKeys.dialog), findsNothing);
  });

  testWidgets('Given Settings › About when Bugs & improvements is pressed '
      'then the report dialog opens', (tester) async {
    await pumpReportShell(tester, h, AboutSection(services: h.services));

    expect(key('settings.about.reportBug'), findsNothing);
    await tester.tap(key('settings.about.board'));
    await tester.pumpAndSettle();

    expect(key(BoardReportKeys.dialog), findsOneWidget);
  });

  group('Given an open document', () {
    Future<void> pumpEditor(WidgetTester tester, double width) async {
      final doc = h.drive.seed(name: 'Plan');
      await pumpReportShell(
        tester,
        h,
        EditorScaffold(
          services: h.services,
          itemUuid: doc.uuid.uuid,
          body: (context, item) => const SizedBox.expand(),
          commentsButton: false,
          historyPanel: false,
          showStatusBar: false,
        ),
        size: Size(width, 800),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> unmount(WidgetTester tester) async {
      // Unmount (the editor keeps animating) so no timers are left.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    }

    for (final (id, icon, label, kind) in [
      ('editor.reportBug', LucideIcons.bug, 'Report a bug', BoardPostKind.bug),
      (
        'editor.suggest',
        LucideIcons.leaf,
        'Suggest an improvement',
        BoardPostKind.idea,
      ),
    ]) {
      for (final (width, labelled) in [(1280.0, true), (800.0, false)]) {
        testWidgets('at $width px when "$label" in the title row is pressed '
            'then the report dialog opens on ${kind.name}', (tester) async {
          await pumpEditor(tester, width);

          expect(key('editor.board'), findsNothing);
          expect(
            find.descendant(of: key(id), matching: find.byIcon(icon)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: key(id), matching: find.text(label)),
            labelled ? findsOneWidget : findsNothing,
          );
          if (labelled) {
            expect(
              tester.widget<ShadButton>(key(id)).variant,
              ShadButtonVariant.outline,
            );
          } else {
            expect(
              tester.widget<ShadIconButton>(key(id)).variant,
              ShadButtonVariant.outline,
            );
          }

          await tester.tap(key(id));
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }

          expect(key(BoardReportKeys.dialog), findsOneWidget);
          expect(dialog(tester).draft.kind, kind);
          await unmount(tester);
        });
      }
    }

    for (final b in Brightness.values) {
      for (final width in [1280.0, 800.0]) {
        testWidgets('in ${b.name} at $width px then the buttons have enough '
            'contrast and are labeled', (tester) async {
          final semantics = tester.ensureSemantics();
          final doc = h.drive.seed(name: 'Plan');
          await pumpReportShell(
            tester,
            h,
            EditorScaffold(
              services: h.services,
              itemUuid: doc.uuid.uuid,
              body: (context, item) => const SizedBox.expand(),
              commentsButton: false,
              historyPanel: false,
              showStatusBar: false,
            ),
            size: Size(width, 800),
            brightness: b,
          );
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }

          await expectAccessible(tester);
          semantics.dispose();
          await unmount(tester);
        });
      }
    }

    testWidgets('below 640 px then the title row has neither button', (
      tester,
    ) async {
      await pumpEditor(tester, 600);
      expect(key('editor.reportBug'), findsNothing);
      expect(key('editor.suggest'), findsNothing);
      await unmount(tester);
    });
  });

  testWidgets('Given the error card when "Report this bug" is pressed then '
      'the dialog opens on Bug with the error attached', (tester) async {
    final details = FlutterErrorDetails(
      exception: StateError('Widget exploded'),
      stack: StackTrace.fromString('#0 main (package:x/y.dart:1:1)'),
    );
    await pumpReportShell(
      tester,
      h,
      ErrorCard(details: details, services: h.services),
    );

    await tester.tap(key('error.reportBug'));
    await tester.pumpAndSettle();

    final d = dialog(tester);
    expect(d.draft.kind, BoardPostKind.bug);
    expect(d.draft.includeError, isTrue);
    expect(find.textContaining('Include the last error'), findsOneWidget);
    await enterField(
      tester,
      BoardReportKeys.field(BoardReportField.title),
      'The card shows an error',
    );
    await enterField(
      tester,
      BoardReportKeys.field(BoardReportField.happened),
      'Exploded',
    );
    await tester.tap(key(BoardReportKeys.post));
    await tester.pumpAndSettle();

    expect(board.posted.single.contextJson, contains('Widget exploded'));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
