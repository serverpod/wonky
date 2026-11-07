import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, UuidValue, WonkyErrorCode, WonkyException;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides/config/slides_app_config.dart';
import 'package:wonky_slides/features/revlog/slides_rev_log.dart';

import 'support/deck_harness.dart';

/// A signed-out viewer of a link-shared presentation (specs/06 §2.4): the
/// item from `publicItem.get`, the rows over the stream into the device's
/// guest cache, view-only whatever the stream says.
void main() {
  late FakeRevHub hub;
  late CommandTestHarness h;
  late FakePublicItemRepository public;
  final owner = UuidValue.fromString('0190a0e0-0000-7000-8000-0000000000f1');
  final file = UuidValue.fromString('0190a0e0-0000-7000-8000-0000000000e2');

  setUp(() async {
    hub = slidesHub();
    commitChanges(hub, file, owner, deckCreation(file, owner));
    final drive = FakeDriveRepository();
    drive.seed(
      name: 'Deck',
      kind: DriveItemKind.presentation,
      uuid: file,
      contentRef: file,
    );
    public = FakePublicItemRepository(drive);
    h = CommandTestHarness(
      config: const SlidesAppConfig(),
      drive: drive,
      auth: FakeAuthRepository(signedIn: false),
      publicItems: public,
    );
    final dir = await Directory.systemTemp.createTemp('wonky_slides_guest_');
    SlidesRevLog.directoryOverride = dir.path;
    SlidesRevLog.guestTransport = () => hub.transport('guest');
    addTearDown(() async {
      await SlidesRevLog.closeGuest(h.services);
      await h.dispose();
      SlidesRevLog.directoryOverride = null;
      SlidesRevLog.guestTransport = null;
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
  });

  test('Given a link-shared presentation when a guest opens it then it '
      'loads from the stream, view-only', () async {
    public.share(file);

    final s = await openDeckSession(h.services, file);
    addTearDown(s.dispose);
    await (s as LoggedDeckSession).opened;
    await whenReady(s);

    expect(s.model.deck?.title, 'Deck');
    // The fake stream grants Editor; a guest still only views.
    expect(s.role.value, Role.viewer);
    expect(public.calls, [file]);
    expect(h.drive.calls, isEmpty);
    expect(await s.client.store.filesWithOutbox(), isEmpty);
  });

  test('Given a presentation that is not link-shared when a guest opens it '
      'then it fails with notFound', () async {
    await expectLater(
      openDeckSession(h.services, file),
      throwsA(
        isA<WonkyException>().having(
          (e) => e.code,
          'code',
          WonkyErrorCode.notFound,
        ),
      ),
    );
  });

  test('Given a guest when a link-shared command that needs an account is '
      'checked then it is disabled, viewing commands are not', () {
    for (final id in const [
      'slides.present.start',
      'slides.comments.openPanel',
      'slides.history.open',
      'shell.sharing.open',
    ]) {
      expect(h.services.config.guestAllowsCommand(id), isFalse, reason: id);
    }
    expect(h.services.config.guestAllowsCommand('slides.view.zoomIn'), isTrue);
    expect(h.services.config.allowsGuestViewing, isTrue);
  });
}
