@Timeout(Duration(minutes: 1))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart'
    show AccessRole, Uuid, UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/codec.dart' show ChangeSet;
import 'package:wonky_sheets_core/model.dart';

import 'support/rev_harness.dart';

final anna = UuidValue.fromString('0190a000-0000-7000-8000-0000000000a1');
final bo = UuidValue.fromString('0190a000-0000-7000-8000-0000000000b2');
final file = UuidValue.fromString('0190a000-0000-7000-8000-0000000000f3');

/// Invariant repairs after remote ops (Sheets 02 §8, RevLog spec 06 §1.2).
void main() {
  late FakeRevHub hub;

  setUp(() {
    hub = sheetsHub();
    commitPlan(hub, file, anna, creationPlan(file, anna, rows: 20, columns: 5));
  });

  /// Another device freezes more rows than the sheet has (a concurrent
  /// row delete would do the same).
  void freezeBeyondGrid(String sheetId) => hub.commit(
    file.uuid,
    anna.uuid,
    ChangeSet(
      clientOpId: const Uuid().v7(),
      baseRevision: hub.file(file.uuid).head,
      changes: [
        RowChange.update(SheetsTables.sheet, sheetId, const {}, {
          SheetCols.frozenRows: 500,
        }),
      ],
      label: 'Freeze',
    ),
  );

  test(
    'Given an editor with the spreadsheet open, when a remote op breaks '
    'an invariant, then the repair is applied and sent as a repair op',
    () async {
      final b = await SheetsDevice.start(hub, bo);
      final s = await b.openFile(file, role: Role.editor);
      final sheet = s.model.sheets.single;

      freezeBeyondGrid(sheet.id);

      await eventually(() => s.repairs == 1);
      expect(s.model.sheet(sheet.id)!.record!.frozenRows, 19);
      await eventually(
        () => hub.file(file.uuid).log.last.summary?['repair'] == true,
      );
    },
  );

  test('Given a viewer, when a remote op breaks an invariant, then nothing '
      'is written', () async {
    hub.setRole(bo.uuid, file.uuid, AccessRole.viewer);
    final b = await SheetsDevice.start(hub, bo);
    final s = await b.openFile(file, role: Role.viewer);
    final head = hub.file(file.uuid).head;

    freezeBeyondGrid(s.model.sheets.single.id);
    await eventually(() => hub.file(file.uuid).head == head + 1);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(s.repairs, 0);
    expect(hub.file(file.uuid).head, head + 1);
  });
}
