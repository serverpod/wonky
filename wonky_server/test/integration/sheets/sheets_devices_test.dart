@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';

import '../../support/sheets_rev_device.dart';
import '../../support/sheets_rev_hooks.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Spreadsheet devices on RevLog (ported from the offline-sync device
/// tests; RevLog spec 09 §3): concurrent edits, roles following sharing,
/// templates and copies, trash.
void main() {
  withWonkyServerpod('Given spreadsheet devices on RevLog', (
    sessionBuilder,
    endpoints,
  ) {
    final devices = <SheetsRevDevice>[];

    SheetsRevHooks.install();
    tearDown(() async {
      for (final d in devices) {
        await d.close();
      }
      devices.clear();
    });

    Future<SheetsRevDevice> device(TestUser u, UuidValue file) async {
      final d = await SheetsRevDevice.open(u, file);
      devices.add(d);
      return d;
    }

    Future<(TestUser, DriveItemView)> ownerWithSpreadsheet(String name) async {
      final owner = await TestUsers.create(sessionBuilder, name: 'Owner');
      final item = await endpoints.drive.createSpreadsheet(
        owner.endpointSession,
        null,
        name,
        null,
      );
      return (owner, item);
    }

    test('when the same cell is edited on two devices, then both converge '
        'to one value', () async {
      final (owner, item) = await ownerWithSpreadsheet('Race');
      final first = await device(owner, item.contentRef!);
      final second = await device(owner, item.contentRef!);

      await first.setCell(2, 2, 'first');
      await second.setCell(2, 2, 'second');
      await first.sync();
      await second.sync();

      final a = first.cell(2, 2);
      expect(a, second.cell(2, 2));
      expect(['s:first', 's:second'], contains(a));
    });

    test('when sharing changes, then the role of an open device follows, '
        'and removed access ends it', () async {
      final (owner, item) = await ownerWithSpreadsheet('Roles');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await TestDrive.share(endpoints, item, owner, bo, AccessRole.viewer);
      final d = await device(bo, item.contentRef!);
      expect(d.role, AccessRole.viewer);
      await expectLater(
        d.setCell(0, 0, 'nope'),
        throwsA(isA<RevDeviceRejected>()),
      );

      await endpoints.sharing.updateRole(
        owner.endpointSession,
        item.uuid,
        bo.id,
        AccessRole.editor,
      );
      await d.sync();
      expect(d.role, AccessRole.editor);
      await d.setCell(0, 0, 'now ok');
      expect(d.cell(0, 0), 's:now ok');

      await endpoints.sharing.remove(owner.endpointSession, item.uuid, bo.id);
      await expectLater(
        SheetsRevDevice.open(bo, item.contentRef!),
        throwsA(isA<StateError>()),
      );
    });

    test('when a spreadsheet is created from a template and copied, then '
        'both load with their cells', () async {
      final user = await TestUsers.create(sessionBuilder);
      final view = await endpoints.drive.createSpreadsheet(
        user.endpointSession,
        null,
        'Budget',
        BuiltinTemplates.byKey('sheets.monthly-budget').uuid,
      );
      final copy = await endpoints.drive.copy(
        user.endpointSession,
        view.uuid,
        'Budget copy',
        null,
        false,
        false,
      );
      expect(copy.contentRef, isNot(view.contentRef));
      final original = await device(user, view.contentRef!);
      final copied = await device(user, copy.contentRef!);

      expect(original.title, 'Budget');
      expect(copied.title, 'Budget copy');
      expect(original.cell(0, 0), isNotNull);
      expect(copied.cell(0, 0), original.cell(0, 0));
    });

    test('when a shared spreadsheet is trashed, then collaborators can no '
        'longer write and the file is read-only for the owner', () async {
      final (owner, item) = await ownerWithSpreadsheet('Trash');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await TestDrive.share(endpoints, item, owner, bo, AccessRole.editor);
      final theirs = await device(bo, item.contentRef!);
      final mine = await device(owner, item.contentRef!);

      await endpoints.drive.trash(owner.endpointSession, [item.uuid]);
      await theirs.sync();
      await mine.sync();

      await expectLater(theirs.setCell(0, 0, 'late'), throwsA(anything));
      await expectLater(
        mine.setCell(0, 0, 'mine'),
        throwsA(
          isA<RevDeviceRejected>().having(
            (e) => e.rejected.code,
            'code',
            RevRejectCode.fileReadOnly,
          ),
        ),
      );
      expect(mine.title, 'Trash');
    });
  });
}
