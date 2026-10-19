import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show CommandStatus;
import 'package:wonky_sheets/features/data_tools/data_job.dart';
import 'package:wonky_sheets/l10n/sheets_l10n.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../support/sheets_harness.dart';

const _rows = DataJobs.threshold + 1;

/// [s] with [_rows] rows and descending numbers in column A.
SheetsHarness _bigSheet() {
  final s = SheetsHarness.open();
  s.session.execute(
    InsertDimension(s.sheetId, Dimension.rows, 1000, _rows - 1000),
  );
  s.session.execute(
    SetCellInputs(
      sheetId: s.sheetId,
      row: 0,
      col: 0,
      inputs: [
        for (var r = 0; r < _rows; r++) [CellInput.user('${_rows - r}')],
      ],
    ),
  );
  return s;
}

/// Pumps an app whose navigator is the shell's, so toasts show.
Future<void> _pumpApp(WidgetTester tester, SheetsHarness s, bool dark) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: s.services,
      child: ShadApp(
        navigatorKey: s.services.navigatorKey,
        theme: dark ? WonkyTheme.dark() : WonkyTheme.light(),
        localizationsDelegates: const [
          WonkyAppLocalizations.delegate,
          WonkyUiLocalizations.delegate,
          SheetsLocalizations.delegate,
        ],
        home: const Material(
          type: MaterialType.transparency,
          child: SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('Given ${_rows - 1}+ rows ($mode), when they are sorted, then '
        'the toast shows the planning progress with Cancel and the sort '
        'lands as one step', (tester) async {
      final s = _bigSheet();
      await _pumpApp(tester, s, dark);
      final steps = s.h.undoLabels.length;

      final run = s.run('sheets.data.sortRange', {
        'range': 'A1:A$_rows',
        'ascending': true,
      });
      final seen = <double>[];
      var toast = false;
      var done = false;
      unawaited(run.then((_) => done = true));
      for (var i = 0; i < 400 && !done; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final p = DataJobs.progressOf(s.editor)?.value;
        if (p != null) seen.add(p);
        if (find
            .byKey(const ValueKey('toast.progress.cancel'))
            .evaluate()
            .isNotEmpty) {
          toast = true;
          expect(find.textContaining('%'), findsWidgets);
        }
      }
      expect((await run).isOk, isTrue);
      expect(toast, isTrue);
      expect(seen.where((p) => p > 0 && p < 1), isNotEmpty);
      expect(s.text('A1'), '1');
      expect(s.text('A$_rows'), '$_rows');
      expect(s.h.undoLabels.length, steps + 1);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await s.dispose();
    });
  }

  testWidgets('Given a long sort, when it is cancelled while planning, then '
      'nothing changes and no undo step is added', (tester) async {
    final s = _bigSheet();
    await _pumpApp(tester, s, false);
    final steps = s.h.undoLabels.length;

    final run = s.run('sheets.data.sortRange', {'range': 'A1:A$_rows'});
    for (var i = 0; i < 10 && DataJobs.progressOf(s.editor) == null; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 16));
    expect(DataJobs.isRunning(s.editor), isTrue);
    DataJobs.cancel(s.editor);
    var done = false;
    unawaited(run.then((_) => done = true));
    for (var i = 0; i < 100 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect((await run).status, CommandStatus.cancelled);
    expect(s.text('A1'), '$_rows');
    expect(s.h.undoLabels.length, steps);
    expect(DataJobs.isRunning(s.editor), isFalse);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await s.dispose();
  });
}
