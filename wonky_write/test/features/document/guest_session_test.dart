import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../sync/support/fake_document_server.dart';
import 'support/session_harness.dart';

/// A signed-out viewer of a link-shared document (specs/06 §2.4): the item
/// comes from `publicItem.get`, nothing is kept on the device, and the
/// document is view-only whatever the link (or the stream) allows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDocumentServer server;
  late SessionHarness h;

  setUp(() {
    server = FakeDocumentServer(initial: Delta()..insert('Hello\n'));
    h = SessionHarness(server, signedIn: false);
  });
  tearDown(() => h.dispose());

  test('Given a link-shared document when a guest opens it then it shows '
      'view-only without drive calls', () async {
    await h.open();

    expect(h.session.phase.value, WriteSessionPhase.ready);
    expect(h.text, 'Hello\n');
    expect(h.session.title, 'Plan');
    expect(h.publicItems.calls, 1);
    expect(h.api.getItemCalls, 0);
    // The fake stream grants Editor; a guest still only views.
    expect(h.session.role.value, Role.viewer);
    expect(h.session.editor.mode, EditorMode.viewing);
    expect(h.session.canUseMode(EditorMode.editing), isFalse);
    expect(h.session.canUseMode(EditorMode.suggesting), isFalse);
  });

  test('Given a document that is not link-shared when a guest opens it then '
      'the session reports no access', () async {
    h.publicItems.shared = false;

    await h.open();

    expect(h.session.phase.value, WriteSessionPhase.noAccess);
    expect(h.api.getItemCalls, 0);
  });

  test('Given a signed-in user when the document opens then the drive item '
      'is loaded as before', () async {
    await h.dispose();
    h = SessionHarness(server);

    await h.open();

    expect(h.session.phase.value, WriteSessionPhase.ready);
    expect(h.api.getItemCalls, 1);
    expect(h.publicItems.calls, 0);
    expect(h.session.role.value, Role.editor);
  });
}
