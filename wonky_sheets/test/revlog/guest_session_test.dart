import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, UuidValue, WonkyErrorCode, WonkyException;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets/config/sheets_app_config.dart';
import 'package:wonky_sheets/features/revlog/sheets_rev_log.dart';

import 'support/rev_harness.dart';

/// A signed-out viewer of a link-shared spreadsheet (specs/06 §2.4): the
/// item from `publicItem.get`, the rows over the stream into the device's
/// guest cache, view-only whatever the stream says.
void main() {
  late FakeRevHub hub;
  late CommandTestHarness h;
  late FakePublicItemRepository public;
  final owner = UuidValue.fromString('0190a0e0-0000-7000-8000-0000000000f1');
  final file = UuidValue.fromString('0190a0e0-0000-7000-8000-0000000000e1');

  setUp(() async {
    hub = sheetsHub();
    commitPlan(hub, file, owner, creationPlan(file, owner, title: 'Budget'));
    final drive = FakeDriveRepository();
    drive.seed(
      name: 'Budget',
      kind: DriveItemKind.spreadsheet,
      uuid: file,
      contentRef: file,
    );
    public = FakePublicItemRepository(drive);
    h = CommandTestHarness(
      config: const SheetsAppConfig(),
      drive: drive,
      auth: FakeAuthRepository(signedIn: false),
      publicItems: public,
    );
    final dir = await Directory.systemTemp.createTemp('wonky_sheets_guest_');
    SheetsRevLog.directoryOverride = dir.path;
    SheetsRevLog.guestTransport = () => hub.transport('guest');
    addTearDown(() async {
      await SheetsRevLog.closeGuest(h.services);
      await h.dispose();
      SheetsRevLog.directoryOverride = null;
      SheetsRevLog.guestTransport = null;
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
  });

  test('Given a link-shared spreadsheet when a guest opens it then it loads '
      'from the stream, view-only', () async {
    public.share(file);

    final s = await openWorkbookSession(h.services, file);
    addTearDown(s.dispose);
    await (s as LoggedWorkbookSession).opened;
    await whenReady(s);

    expect(s.model.sheets, isNotEmpty);
    // The fake stream grants Editor; a guest still only views.
    expect(s.role.value, Role.viewer);
    expect(public.calls, [file]);
    expect(h.drive.calls, isEmpty);
    expect(await s.client.store.filesWithOutbox(), isEmpty);
  });

  test('Given a spreadsheet that is not link-shared when a guest opens it '
      'then it fails with notFound', () async {
    await expectLater(
      openWorkbookSession(h.services, file),
      throwsA(
        isA<WonkyException>().having(
          (e) => e.code,
          'code',
          WonkyErrorCode.notFound,
        ),
      ),
    );
    expect(SheetsRevLog.current(h.services), isNull);
  });
}
