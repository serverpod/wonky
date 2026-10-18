import 'package:flutter/material.dart' show Material, MaterialType, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart';

import 'screen_harness.dart';

/// Like [ScreenHarness.pump], in [brightness]: pumps [child] inside a shad
/// app with [h]'s shell services provided and records the invoked commands
/// in [ScreenHarness.invoked].
Future<void> pumpScreen(
  WidgetTester tester,
  ScreenHarness h,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = const Size(1400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  h.services.dispatcher.events.listen((e) => h.invoked.add(e.id.value));
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: h.services,
      child: ShadApp(
        theme: WonkyTheme.light(),
        darkTheme: WonkyTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
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

/// Lets a command dispatched from a control run to completion (the
/// dispatcher completes on the event loop).
Future<void> settleCommand(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(pumpEventQueue);
  await tester.pump();
}
