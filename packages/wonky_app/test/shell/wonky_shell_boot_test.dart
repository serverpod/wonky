import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';

/// CQ-45 (H-6): the shell renders from the device first and loads the
/// profile and preferences without blocking the first real frame.
void main() {
  late CommandTestHarness h;

  setUp(() {
    h = CommandTestHarness(registerShellCommands: false);
    // As at start-up: nobody is known until the shell loads them.
    h.services.currentUser.value = null;
  });

  late ErrorWidgetBuilder errorBuilder;

  Future<void> pumpShell(WidgetTester tester) async {
    errorBuilder = ErrorWidget.builder;
    await tester.pumpWidget(
      WonkyShell(config: const TestAppConfig(), services: h.services),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Started by the shell; the app never stops it.
    h.services.connectivity.dispose();
    await tester.pump(const Duration(seconds: 5));
    // The shell installs its error boundary.
    ErrorWidget.builder = errorBuilder;
  }

  testWidgets('Given a signed-in device with a cached profile when the '
      'server is slow then the shell is ready with the cached profile', (
    tester,
  ) async {
    h.users
      ..cachedProfile = h.users.profile
      ..getMeGate = Completer<void>();

    await pumpShell(tester);

    expect(find.byType(ShadSpinner), findsNothing);
    expect(h.services.currentUser.value?.summary.uuid, TestUsers.anna.uuid);
    expect(h.users.getMeCalls, 1);
    h.users.getMeGate!.complete();
    await tester.pump();
    await unmount(tester);
  });

  testWidgets('Given a signed-in device without a cached profile when the '
      'server is slow then the shell waits for the profile', (tester) async {
    h.users.getMeGate = Completer<void>();

    await pumpShell(tester);

    expect(find.byType(ShadSpinner), findsOneWidget);
    expect(h.services.currentUser.value, isNull);

    h.users.getMeGate!.complete();
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    expect(find.byType(ShadSpinner), findsNothing);
    expect(h.services.currentUser.value?.summary.uuid, TestUsers.anna.uuid);
    await unmount(tester);
  });
}
