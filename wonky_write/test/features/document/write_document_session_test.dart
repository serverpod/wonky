import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart' show SyncState;
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../sync/support/fake_document_server.dart';
import 'support/session_harness.dart';

Delta _ins(int at, String text, [Map<String, dynamic>? attrs]) => Delta()
  ..retain(at)
  ..insert(text, attrs);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Given an editor opening a document', () {
    late FakeDocumentServer server;
    late SessionHarness h;

    setUp(() async {
      server = FakeDocumentServer(initial: Delta()..insert('Hello\n'));
      h = SessionHarness(server);
      await h.open();
    });

    tearDown(() => h.dispose());

    test(
      'when the stream initializes then the session is ready in Editing mode',
      () {
        expect(h.session.phase.value, WriteSessionPhase.ready);
        expect(h.text, 'Hello\n');
        expect(h.session.role.value, Role.editor);
        expect(h.session.editor.mode, EditorMode.editing);
        expect(h.session.syncStatus.value.state, SyncState.saved);
        expect(h.session.title, 'Plan');
      },
    );

    test(
      'when typing then the change reaches the server and is undoable',
      () async {
        h.session.editor.applyLocal(
          _ins(5, ' world'),
          label: 'Typing',
          source: LocalChangeSource.input,
        );
        await pumpEventQueue();

        expect(DeltaUtils.text(server.document), 'Hello world\n');
        expect(h.undo.undoLabel.value, 'Typing');

        await h.undo.undo();
        await pumpEventQueue();
        expect(h.text, 'Hello\n');
        expect(DeltaUtils.text(server.document), 'Hello\n');

        await h.undo.redo();
        await pumpEventQueue();
        expect(DeltaUtils.text(server.document), 'Hello world\n');
      },
    );

    test(
      'when a collaborator types above the own change then undo only reverts the own change',
      () async {
        h.session.editor.applyLocal(
          _ins(5, '!'),
          label: 'Typing',
          source: LocalChangeSource.input,
        );
        await pumpEventQueue();
        server.commitExternal(_ins(0, 'Bo: '));
        await pumpEventQueue();
        expect(h.text, 'Bo: Hello!\n');

        await h.undo.undo();
        await pumpEventQueue();

        expect(h.text, 'Bo: Hello\n');
        expect(server.document, h.doc);
      },
    );

    test('when undoing then the rebased selection is restored', () async {
      h.session.editor.select(const DeltaSelection.collapsed(5));
      h.session.editor.applyLocal(
        _ins(5, '!'),
        label: 'Typing',
        source: LocalChangeSource.input,
      );
      await pumpEventQueue();
      server.commitExternal(_ins(0, 'XY'));
      await pumpEventQueue();

      await h.undo.undo();

      expect(h.session.editor.selection, const DeltaSelection.collapsed(7));
      expect(h.session.shouldRestoreSelection(), isFalse);
    });

    test(
      'when the page setup changes then it is written and undoable',
      () async {
        final setup = PageSetup.defaultsFor('en-US');
        await h.session.setPageSetup(setup);
        await pumpEventQueue();

        expect(h.api.metaWrites.single.$1, 'pageSetup');
        expect(h.session.meta.value.pageSetup, setup);
        expect(h.undo.undoLabel.value, 'Change page setup');

        await h.undo.undo();
        await pumpEventQueue();
        expect(h.api.metaWrites.last, ('pageSetup', '{}'));
      },
    );

    test(
      'when someone else changes the theme afterwards then the theme step is dropped',
      () async {
        await h.session.setTheme('00000000-0000-7000-8000-00000000f001');
        await pumpEventQueue();
        expect(h.undo.canUndo.value, isTrue);

        server.changeMeta(
          'themeId',
          jsonEncode('00000000-0000-7000-8000-00000000f002'),
        );
        await pumpEventQueue();

        expect(h.undo.canUndo.value, isFalse);
      },
    );

    test(
      'when the role is downgraded to commenter then the mode switches to Suggesting',
      () async {
        server.setRole(1, AccessRole.commenter);
        await pumpEventQueue();

        expect(h.session.role.value, Role.commenter);
        expect(h.session.editor.mode, EditorMode.suggesting);
        expect(h.session.canUseMode(EditorMode.editing), isFalse);
      },
    );

    test(
      'when an unallowed mode is set directly then it is reverted',
      () async {
        server.setRole(1, AccessRole.viewer);
        await pumpEventQueue();
        h.session.editor.mode = EditorMode.editing;
        await pumpEventQueue();

        expect(h.session.editor.mode, EditorMode.viewing);
      },
    );
  });

  group('Given two sessions on the same document', () {
    test(
      'when both edit concurrently then both converge with the server',
      () async {
        final server = FakeDocumentServer(initial: Delta()..insert('ab\n'));
        final a = SessionHarness(server, userId: 1);
        final b = SessionHarness(server, userId: 2);
        await a.open();
        await b.open();

        a.session.editor.applyLocal(
          _ins(1, 'X'),
          label: 'Typing',
          source: LocalChangeSource.input,
        );
        b.session.editor.applyLocal(
          _ins(2, 'Y'),
          label: 'Typing',
          source: LocalChangeSource.input,
        );
        await pumpEventQueue();

        expect(a.doc, server.document);
        expect(b.doc, server.document);
        expect(DeltaUtils.text(server.document), 'aXbY\n');

        // B sees A's caret.
        a.session.editor.select(const DeltaSelection.collapsed(2));
        a.session.presence.flush();
        await pumpEventQueue();
        final cursors = b.session.editor.view.remoteCursors.toList();
        expect(cursors, hasLength(1));
        expect(cursors.single.name, 'User 1');
        expect(cursors.single.selection, const DeltaSelection.collapsed(2));

        await a.dispose();
        await b.dispose();
      },
    );
  });

  group('Given a commenter in Suggesting mode', () {
    test('when the author withdraws a suggestion then it disappears', () async {
      final server = FakeDocumentServer(initial: Delta()..insert('Hello\n'));
      final h = SessionHarness(server, role: AccessRole.commenter);
      server.setRole(1, AccessRole.commenter);
      await h.open();
      expect(h.session.editor.mode, EditorMode.suggesting);

      h.session.editor.applyLocal(
        _ins(5, ' there'),
        label: 'Typing',
        source: LocalChangeSource.input,
      );
      await pumpEventQueue();
      final pending = h.session.suggestions.pending;
      expect(pending, hasLength(1));
      expect(h.session.suggestions.canDecide, isFalse);
      expect(h.session.suggestions.canReject(pending.single), isTrue);

      expect(h.session.suggestions.reject({pending.single.id}), isTrue);
      await pumpEventQueue();

      expect(h.text, 'Hello\n');
      expect(DeltaUtils.text(server.document), 'Hello\n');
      await h.dispose();
    });
  });

  group('Given an editor reviewing a suggestion', () {
    test(
      'when accepting it then the text stays and the mark is gone, and undo brings it back',
      () async {
        const by = '00000000-0000-7000-8000-000000000002';
        final server = FakeDocumentServer(
          initial: Delta()
            ..insert('Hello')
            ..insert(' there', {
              'sug_s1': {'t': 'ins', 'by': by, 'at': 5},
            })
            ..insert('\n'),
        );
        final h = SessionHarness(server);
        await h.open();
        expect(h.session.suggestions.pending.single.id, 's1');

        expect(h.session.suggestions.accept({'s1'}), isTrue);
        await pumpEventQueue();
        expect(h.session.suggestions.pending, isEmpty);
        expect(DeltaUtils.text(server.document), 'Hello there\n');
        expect(h.undo.undoLabel.value, 'Accept suggestion');

        await h.undo.undo();
        await pumpEventQueue();
        expect(h.session.suggestions.pending.single.id, 's1');
        expect(server.document, h.doc);
        await h.dispose();
      },
    );

    test(
      'when rejecting all then every suggestion is removed in one step',
      () async {
        const by = '00000000-0000-7000-8000-000000000002';
        final server = FakeDocumentServer(
          initial: Delta()
            ..insert('A', {
              'sug_a': {'t': 'ins', 'by': by, 'at': 1},
            })
            ..insert('bc')
            ..insert('d', {
              'sug_b': {'t': 'del', 'by': by, 'at': 1},
            })
            ..insert('\n'),
        );
        final h = SessionHarness(server);
        await h.open();

        expect(h.session.suggestions.rejectAll(), isTrue);
        await pumpEventQueue();

        expect(DeltaUtils.text(server.document), 'bcd\n');
        expect(h.session.suggestions.pending, isEmpty);
        expect(h.undo.undoStepsOf(h.session.undoStackKey), hasLength(1));
        await h.dispose();
      },
    );
  });
}
