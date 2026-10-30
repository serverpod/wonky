import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/material.dart' show ShadMaterial;
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show KeyScope;
import 'package:wonky_sheets/features/cell_editor/cell_editor_controller.dart';
import 'package:wonky_sheets/features/grid/grid_area.dart';
import 'package:wonky_sheets/l10n/sheets_l10n.dart';
import 'package:wonky_ui/wonky_ui.dart';

import 'sheets_harness.dart';

/// Pumps [child] (default: the grid of [s]) inside a shad app with the
/// shell services provided, at [size].
Future<void> pumpSheets(
  WidgetTester tester,
  SheetsHarness s, {
  Widget? child,
  Size size = const Size(1200, 800),
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: s.services,
      child: ShadApp(
        theme: dark ? WonkyTheme.dark() : WonkyTheme.light(),
        localizationsDelegates: const [
          WonkyAppLocalizations.delegate,
          WonkyUiLocalizations.delegate,
          SheetsLocalizations.delegate,
        ],
        builder: (context, child) => ShadMaterial(child: child!),
        home: WonkyThemeScope(
          data: const WonkyThemeExtension(),
          child: KeymapScope(
            scope: KeyScope.global,
            keymap: s.services.keymap,
            child:
                child ?? GridArea(controller: s.editor, services: s.services),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Types [chars] like a keyboard/IME would: through the text input of the
/// focused cell editor field (the grid's "ready" state or an open edit).
Future<void> typeChars(
  WidgetTester tester,
  CellEditorController editor,
  String chars,
) async {
  final current = editor.text.value;
  final sel = current.selection.isValid
      ? current.selection
      : TextSelection.collapsed(offset: current.text.length);
  final next = current.text.replaceRange(sel.start, sel.end, chars);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: sel.start + chars.length),
    ),
  );
  await tester.pump();
}
