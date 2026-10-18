// Changes the server rejects (RevLog spec 06 §4.6): the model rolls back
// and the plan's undo step is removed.
@Timeout(Duration(minutes: 1))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_revlog/apply.dart' show RevRejectReason;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart'
    show RevGroupRejection;
import 'package:wonky_sheets/features/revlog/logged_workbook_session.dart';

import '../../revlog/support/rev_harness.dart';
import 'support/collab_harness.dart';

final anna = UuidValue.fromString('0190a000-0000-7000-8000-0000000000a1');
final bo = UuidValue.fromString('0190a000-0000-7000-8000-0000000000b2');
final file = UuidValue.fromString(collabItemUuid);

void main() {
  group('Given Bo editing a shared spreadsheet', () {
    late FakeRevHub hub;
    late CollabHarness s;

    setUp(() async {
      hub = sheetsHub();
      final a = await SheetsDevice.start(hub, anna);
      final sa = await a.create(file, rows: 20, columns: 5);
      await sa.whenSynced(timeout: const Duration(seconds: 10));
      final b = await SheetsDevice.start(hub, bo);
      final session = await b.openFile(file);
      s = await CollabHarness.open(session: session);
      addTearDown(s.dispose);
    });

    test('when the server no longer lets him edit, then his edit rolls back '
        'and its undo step is gone', () async {
      // Revoked on the server; the client hasn't heard yet.
      hub.file(file.uuid).setReadOnly(bo.uuid);
      final rejected = <RevGroupRejection>[];
      final session = s.session as LoggedWorkbookSession;
      final sub = session.groupRejected.listen(rejected.add);
      addTearDown(sub.cancel);

      await s.type('B2', 'Bo was here');
      expect(s.text('B2'), 'Bo was here');
      final stack = UndoStackKey(collabItemUuid);
      expect(s.services.undo.undoStepsOf(stack), hasLength(1));

      await eventually(() => rejected.isNotEmpty);
      await pumpEventQueue();
      expect(
        rejected.single.rejection.reason,
        RevRejectReason.forbiddenForRole,
      );
      expect(s.text('B2'), '');
      expect(s.services.undo.undoStepsOf(stack), isEmpty);
    });
  });
}
