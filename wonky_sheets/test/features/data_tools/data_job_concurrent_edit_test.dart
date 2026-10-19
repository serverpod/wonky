import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show CommandResult, CommandStatus;
import 'package:wonky_sheets/features/data_tools/data_job.dart';
import 'package:wonky_sheets/l10n/sheets_l10n.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../support/sheets_harness.dart';

const _rows = DataJobs.threshold + 1;

/// A sheet with [_rows] rows and descending numbers in column A (as in
/// `data_job_progress_test.dart`).
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

/// Pumps an app whose navigator is the shell's, so the job's toast shows.
Future<void> _pumpApp(WidgetTester tester, SheetsHarness s) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: s.services,
      child: ShadApp(
        navigatorKey: s.services.navigatorKey,
        theme: WonkyTheme.light(),
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

/// Pumps frames until [f] completes (at most [frames]).
Future<T> _pumpUntil<T>(
  WidgetTester tester,
  Future<T> f, {
  int frames = 400,
}) async {
  var done = false;
  unawaited(f.then((_) => done = true));
  for (var i = 0; i < frames && !done; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return f;
}

/// Starts sorting column A (the command's result).
Future<CommandResult> _sort(SheetsHarness s) =>
    s.run('sheets.data.sortRange', {'range': 'A1:A$_rows', 'ascending': true});

/// Pumps until the sort plans in cooperative steps.
Future<void> _untilPlanning(WidgetTester tester, SheetsHarness s) async {
  for (var i = 0; i < 10 && DataJobs.progressOf(s.editor) == null; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 16));
  expect(DataJobs.isRunning(s.editor), isTrue);
}

/// Editing while a long data job runs (Sheets S-02, T-03; fixed by CQ-10:
/// the dispatcher's undo transaction is scoped to the command's own async
/// call chain): a cell typed while a sort plans in cooperative steps is its
/// own undo step, and cancelling the sort does not roll it back.
void main() {
  testWidgets('Given a long sort, when a cell is typed while it plans, then '
      'the edit and the sort are separate undo steps', (tester) async {
    final s = _bigSheet();
    await _pumpApp(tester, s);
    final steps = s.h.undoLabels.length;
    final run = _sort(s);
    await _untilPlanning(tester, s);

    await _pumpUntil(tester, s.type('C1', 'typed'));
    expect(DataJobs.isRunning(s.editor), isTrue);
    expect((await _pumpUntil(tester, run)).isOk, isTrue);

    expect(s.text('A1'), '1');
    expect(s.text('C1'), 'typed');
    expect(s.h.undoLabels, hasLength(steps + 2));

    // The sort finished last, so it is the newest step: undoing it keeps
    // the edit.
    await _pumpUntil(tester, s.undo());
    expect(s.text('A1'), '$_rows');
    expect(s.text('C1'), 'typed');

    // The edit is a step of its own.
    await _pumpUntil(tester, s.undo());
    expect(s.text('C1'), '');
    expect(s.text('A1'), '$_rows');
    expect(s.h.undoLabels, hasLength(steps));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    await s.dispose();
  });

  testWidgets('Given a long sort, when a cell is typed and undone while it '
      'plans, then undo reverts only the edit and the sort still lands as '
      'one step', (tester) async {
    final s = _bigSheet();
    await _pumpApp(tester, s);
    final steps = s.h.undoLabels.length;
    final run = _sort(s);
    await _untilPlanning(tester, s);

    await _pumpUntil(tester, s.type('C1', 'typed'));
    await _pumpUntil(tester, s.undo());
    expect(s.text('C1'), '');
    expect(DataJobs.isRunning(s.editor), isTrue);
    expect((await _pumpUntil(tester, run)).isOk, isTrue);

    expect(s.text('A1'), '1');
    expect(s.text('C1'), '');
    expect(s.h.undoLabels, hasLength(steps + 1));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    await s.dispose();
  });

  testWidgets('Given a long sort, when a cell is typed while it plans and '
      'the sort is cancelled, then the typed value stays and undo reverts '
      'only the edit', (tester) async {
    final s = _bigSheet();
    await _pumpApp(tester, s);
    final steps = s.h.undoLabels.length;
    final run = _sort(s);
    await _untilPlanning(tester, s);

    await _pumpUntil(tester, s.type('C1', 'typed'));
    expect(DataJobs.isRunning(s.editor), isTrue);
    DataJobs.cancel(s.editor);
    final result = await _pumpUntil(tester, run, frames: 100);

    expect(result.status, CommandStatus.cancelled);
    expect(s.text('C1'), 'typed');
    expect(s.text('A1'), '$_rows');
    expect(s.h.undoLabels, hasLength(steps + 1));

    await _pumpUntil(tester, s.undo());
    expect(s.text('C1'), '');
    expect(s.text('A1'), '$_rows');
    expect(s.h.undoLabels, hasLength(steps));

    await tester.pumpAndSettle(const Duration(seconds: 5));
    await s.dispose();
  });
}
