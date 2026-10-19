import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_core/wonky_core.dart';

import '../support/sheets_harness.dart';

/// Suite 08 §4: every registered `sheets.*` command, executed headless on a
/// small sheet (A1 = 1, A2 = "two", B1 = =A1*2, A1:B2 selected), then undone
/// and redone; the rows must match before and after.
void main() {
  test('Given every Sheets command when it runs, is undone and redone then '
      'the rows round-trip and nothing changes without an undo step', () async {
    final probe = SheetsHarness.open();
    final commands = [
      for (final c in probe.services.registry.all)
        if (c.id.value.startsWith('sheets.')) c,
    ]..sort((a, b) => a.id.value.compareTo(b.id.value));
    await probe.dispose();

    final report = await sweepCommands(
      commands: commands,
      open: _SheetsFixture.open,
      args: _args,
      skip: const {
        'sheets.edit.undo': 'undo itself',
        'sheets.edit.redo': 'redo itself',
        'sheets.edit.repeatLast': 'repeats another command',
      },
      noUndoStep: const {
        'sheets.script.openEditor':
            'creates the bound script project on first open (09 §4)',
      },
    );

    printOnFailure(report.describe());
    expect(report.violations, isEmpty);
    expect(
      report.idsWith(SweepOutcome.roundTrip).length,
      greaterThanOrEqualTo(_minRoundTrips),
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Commands covered by a full round trip (raise it when adding arguments).
const _minRoundTrips = 63;

/// Arguments for commands whose sampled ones do not fit the fixture.
const _args = <String, Map<String, Object?>>{
  'sheets.cell.setInput': {'a1': 'C3', 'input': '5'},
};

class _SheetsFixture implements SweepFixture {
  _SheetsFixture(this.s);

  final SheetsHarness s;

  static Future<SweepFixture> open() async {
    final s = SheetsHarness.open();
    await s.type('A1', '1');
    await s.type('A2', 'two');
    await s.type('B1', '=A1*2');
    await s.select('A1:B2');
    return _SheetsFixture(s);
  }

  @override
  Future<CommandResult> invoke(String id, Map<String, Object?> args) =>
      s.run(id, args);

  @override
  Future<void> undo() => s.undo();

  @override
  Future<void> redo() => s.redo();

  @override
  int get undoSteps => s.services.undo.history().length;

  @override
  Object? snapshot() => ([
    for (final (table, columns) in s.model.allRows())
      jsonEncode([table, columns], toEncodable: (o) => '$o'),
  ]..sort()).join('\n');

  @override
  Future<void> dispose() => s.dispose();
}
